import os
import logging
import requests
from typing import Dict, Any

logger = logging.getLogger(__name__)


def slack_failure_callback(context: Dict[str, Any]) -> None:
    """
    Airflow task failure callback sending formatted failure alerts to Slack.
    """
    webhook_url = os.getenv("SLACK_WEBHOOK_URL")
    if not webhook_url:
        logger.warning("SLACK_WEBHOOK_URL is not configured. Skipping alert.")
        return

    task_instance = context.get("task_instance")
    dag_id = context.get("dag").dag_id if context.get("dag") else "Unknown DAG"
    task_id = task_instance.task_id if task_instance else "Unknown Task"
    execution_date = context.get("execution_date") or context.get("logical_date")
    log_url = task_instance.log_url if task_instance else ""
    exception = context.get("exception")

    message = {
        "text": f"🚨 *Airflow Task Failure Alert* 🚨",
        "attachments": [
            {
                "color": "#E01E5A",
                "fields": [
                    {"title": "DAG", "value": dag_id, "short": True},
                    {"title": "Task", "value": task_id, "short": True},
                    {"title": "Execution Date", "value": str(execution_date), "short": False},
                    {"title": "Exception", "value": str(exception)[:300], "short": False},
                ],
                "actions": [
                    {
                        "type": "button",
                        "text": "View Task Logs",
                        "url": log_url,
                    }
                ] if log_url else [],
            }
        ],
    }

    try:
        response = requests.post(webhook_url, json=message, timeout=10)
        response.raise_for_status()
        logger.info(f"Slack failure notification sent for task {task_id}")
    except Exception as e:
        logger.error(f"Failed to send Slack alert: {e}")


def discord_failure_callback(context: Dict[str, Any]) -> None:
    """
    Airflow task failure callback sending formatted failure alerts to Discord.
    """
    webhook_url = os.getenv("DISCORD_WEBHOOK_URL")
    if not webhook_url:
        logger.warning("DISCORD_WEBHOOK_URL is not configured. Skipping alert.")
        return

    task_instance = context.get("task_instance")
    dag_id = context.get("dag").dag_id if context.get("dag") else "Unknown DAG"
    task_id = task_instance.task_id if task_instance else "Unknown Task"
    execution_date = context.get("execution_date") or context.get("logical_date")
    exception = context.get("exception")

    payload = {
        "embeds": [
            {
                "title": "🚨 Airflow Pipeline Failure",
                "color": 15158332,
                "fields": [
                    {"name": "DAG ID", "value": dag_id, "inline": True},
                    {"name": "Task ID", "value": task_id, "inline": True},
                    {"name": "Execution Date", "value": str(execution_date), "inline": False},
                    {"name": "Error Details", "value": f"```{str(exception)[:500]}```", "inline": False},
                ],
            }
        ]
    }

    try:
        response = requests.post(webhook_url, json=payload, timeout=10)
        response.raise_for_status()
        logger.info(f"Discord failure notification sent for task {task_id}")
    except Exception as e:
        logger.error(f"Failed to send Discord alert: {e}")


def sla_miss_callback(dag, task_list, blocking_task_list, slas, blocking_tis) -> None:
    """
    Airflow SLA Miss callback sending notification alerts to Slack and Discord.
    """
    dag_id = dag.dag_id if dag else "Unknown DAG"
    message_text = f"⏰ *Airflow SLA Miss Alert* - DAG: `{dag_id}` | Tasks: `{task_list}` | Blocking: `{blocking_task_list}`"
    
    # Send Slack alert if configured
    slack_url = os.getenv("SLACK_WEBHOOK_URL")
    if slack_url:
        try:
            requests.post(slack_url, json={"text": message_text}, timeout=10)
            logger.info("SLA miss alert sent to Slack.")
        except Exception as e:
            logger.error(f"Failed to send SLA miss alert to Slack: {e}")

    # Send Discord alert if configured
    discord_url = os.getenv("DISCORD_WEBHOOK_URL")
    if discord_url:
        try:
            payload = {
                "embeds": [
                    {
                        "title": "⏰ Airflow SLA Miss Warning",
                        "color": 16753920,
                        "fields": [
                            {"name": "DAG ID", "value": dag_id, "inline": True},
                            {"name": "Task List", "value": str(task_list), "inline": False},
                            {"name": "Blocking Tasks", "value": str(blocking_task_list), "inline": False},
                        ],
                    }
                ]
            }
            requests.post(discord_url, json=payload, timeout=10)
            logger.info("SLA miss alert sent to Discord.")
        except Exception as e:
            logger.error(f"Failed to send SLA miss alert to Discord: {e}")

