"""
Azure Security Client
Handles all interactions with Azure security services:
- Microsoft Defender for Cloud (security alerts, secure score, recommendations)
- Log Analytics (KQL queries against activity logs)
- Azure Resource Graph (resource inventory)
"""

import logging
from datetime import datetime, timedelta, timezone

from azure.identity import DefaultAzureCredential
from azure.mgmt.security import SecurityCenter
from azure.mgmt.resource import ResourceManagementClient
from azure.monitor.query import LogsQueryClient, LogsQueryStatus
from azure.mgmt.monitor import MonitorManagementClient

logger = logging.getLogger(__name__)


class AzureSecurityClient:
    """Centralized client for Azure security data retrieval."""

    def __init__(self, subscription_id: str, workspace_id: str):
        self.subscription_id = subscription_id
        self.workspace_id = workspace_id
        self.credential = DefaultAzureCredential()

        # Initialize SDK clients
        self.security_client = SecurityCenter(
            credential=self.credential,
            subscription_id=self.subscription_id,
            asc_location="eastus",
        )
        self.resource_client = ResourceManagementClient(
            credential=self.credential,
            subscription_id=self.subscription_id,
        )
        self.logs_client = LogsQueryClient(credential=self.credential)
        self.monitor_client = MonitorManagementClient(
            credential=self.credential,
            subscription_id=self.subscription_id,
        )

    def get_secure_score(self) -> dict:
        """Retrieve the overall Secure Score from Defender for Cloud."""
        try:
            scores = list(self.security_client.secure_scores.list())
            if scores:
                score = scores[0]
                return {
                    "current": round(score.score.current, 2),
                    "max": round(score.score.max, 2),
                    "percentage": round(score.score.percentage * 100, 1),
                    "weight": score.weight,
                }
            return {"current": 0, "max": 0, "percentage": 0, "weight": 0}
        except Exception as e:
            logger.error(f"Failed to fetch secure score: {e}")
            return {"current": 0, "max": 0, "percentage": 0, "weight": 0, "error": str(e)}

    def get_security_alerts(self, limit: int = 50) -> list:
        """Retrieve security alerts from Defender for Cloud."""
        try:
            alerts = []
            for alert in self.security_client.alerts.list():
                alerts.append({
                    "name": alert.alert_display_name,
                    "severity": alert.severity,
                    "status": alert.status,
                    "description": alert.description,
                    "time": alert.time_generated_utc.isoformat() if alert.time_generated_utc else None,
                    "resource": alert.compromised_entity,
                    "tactics": alert.intent if hasattr(alert, "intent") else None,
                    "uri": alert.alert_uri,
                })
                if len(alerts) >= limit:
                    break
            return sorted(alerts, key=lambda x: x["time"] or "", reverse=True)
        except Exception as e:
            logger.error(f"Failed to fetch security alerts: {e}")
            return []

    def get_recommendations(self, limit: int = 25) -> list:
        """Retrieve security recommendations from Defender for Cloud."""
        try:
            recs = []
            for rec in self.security_client.assessments.list(
                scope=f"/subscriptions/{self.subscription_id}"
            ):
                status = rec.status
                recs.append({
                    "name": rec.display_name,
                    "status": status.code if status else "Unknown",
                    "description": rec.additional_data.get("description", "") if rec.additional_data else "",
                    "severity": rec.metadata.severity if rec.metadata else "Unknown",
                    "category": rec.metadata.categories[0] if rec.metadata and rec.metadata.categories else "General",
                })
                if len(recs) >= limit:
                    break
            return recs
        except Exception as e:
            logger.error(f"Failed to fetch recommendations: {e}")
            return []

    def query_activity_log(self, hours: int = 24, limit: int = 100) -> list:
        """Query Azure Activity Log via Log Analytics using KQL."""
        try:
            query = f"""
            AzureActivity
            | where TimeGenerated > ago({hours}h)
            | project
                TimeGenerated,
                OperationNameValue,
                CategoryValue,
                Level,
                Caller,
                CallerIpAddress,
                ResourceGroup,
                ResourceProviderValue,
                ActivityStatusValue,
                Properties
            | order by TimeGenerated desc
            | take {limit}
            """
            response = self.logs_client.query_workspace(
                workspace_id=self.workspace_id,
                query=query,
                timespan=timedelta(hours=hours),
            )

            if response.status == LogsQueryStatus.SUCCESS:
                events = []
                for row in response.tables[0].rows:
                    columns = response.tables[0].columns
                    event = {col.name: val for col, val in zip(columns, row)}
                    # Convert datetime objects to strings
                    for key, val in event.items():
                        if isinstance(val, datetime):
                            event[key] = val.isoformat()
                    events.append(event)
                return events
            else:
                logger.warning(f"KQL query partial failure: {response.partial_error}")
                return []
        except Exception as e:
            logger.error(f"Failed to query activity log: {e}")
            return []

    def query_sign_in_failures(self, hours: int = 24) -> list:
        """Query failed sign-in attempts from Log Analytics."""
        try:
            query = f"""
            SigninLogs
            | where TimeGenerated > ago({hours}h)
            | where ResultType != "0"
            | summarize FailureCount = count() by
                UserPrincipalName,
                IPAddress,
                ResultDescription,
                AppDisplayName
            | order by FailureCount desc
            | take 20
            """
            response = self.logs_client.query_workspace(
                workspace_id=self.workspace_id,
                query=query,
                timespan=timedelta(hours=hours),
            )

            if response.status == LogsQueryStatus.SUCCESS:
                failures = []
                for row in response.tables[0].rows:
                    columns = response.tables[0].columns
                    failure = {col.name: val for col, val in zip(columns, row)}
                    failures.append(failure)
                return failures
            return []
        except Exception as e:
            logger.error(f"Failed to query sign-in failures: {e}")
            return []

    def get_resource_inventory(self) -> dict:
        """Get a count of resources by type in the subscription."""
        try:
            resources = list(self.resource_client.resources.list())
            inventory = {}
            for r in resources:
                rtype = r.type.split("/")[-1] if r.type else "Unknown"
                inventory[rtype] = inventory.get(rtype, 0) + 1
            return {
                "total_count": len(resources),
                "by_type": dict(sorted(inventory.items(), key=lambda x: x[1], reverse=True)),
            }
        except Exception as e:
            logger.error(f"Failed to fetch resource inventory: {e}")
            return {"total_count": 0, "by_type": {}, "error": str(e)}

    def get_dashboard_summary(self) -> dict:
        """Aggregate all data needed for the main dashboard view."""
        return {
            "secure_score": self.get_secure_score(),
            "alerts": self.get_security_alerts(limit=10),
            "recommendations": self.get_recommendations(limit=10),
            "activity": self.query_activity_log(hours=24, limit=20),
            "resources": self.get_resource_inventory(),
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
