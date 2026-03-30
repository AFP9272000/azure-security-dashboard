"""
Azure Security Dashboard - Main Application
Enterprise-grade security monitoring dashboard for Azure environments.
"""

import os
import logging

from flask import Flask, render_template, jsonify
from dotenv import load_dotenv

from app.azure_client import AzureSecurityClient

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize Azure client
subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
workspace_id = os.getenv("LOG_ANALYTICS_WORKSPACE_ID")

if not subscription_id or not workspace_id:
    logger.warning(
        "AZURE_SUBSCRIPTION_ID or LOG_ANALYTICS_WORKSPACE_ID not set. "
        "Dashboard will run but cannot fetch live data."
    )
    azure_client = None
else:
    azure_client = AzureSecurityClient(subscription_id, workspace_id)


@app.route("/")
def dashboard():
    """Main dashboard view with security overview."""
    data = {}
    error = None
    if azure_client:
        try:
            data = azure_client.get_dashboard_summary()
        except Exception as e:
            logger.error(f"Dashboard data fetch failed: {e}")
            error = str(e)
    else:
        error = "Azure credentials not configured"
    return render_template("dashboard.html", data=data, error=error)


@app.route("/alerts")
def alerts():
    """Detailed security alerts view."""
    alerts_data = []
    error = None
    if azure_client:
        try:
            alerts_data = azure_client.get_security_alerts(limit=50)
        except Exception as e:
            logger.error(f"Alerts fetch failed: {e}")
            error = str(e)
    else:
        error = "Azure credentials not configured"
    return render_template("alerts.html", alerts=alerts_data, error=error)


@app.route("/activity")
def activity():
    """Activity log view."""
    activity_data = []
    error = None
    if azure_client:
        try:
            activity_data = azure_client.query_activity_log(hours=48, limit=100)
        except Exception as e:
            logger.error(f"Activity log fetch failed: {e}")
            error = str(e)
    else:
        error = "Azure credentials not configured"
    return render_template("activity.html", activity=activity_data, error=error)


# --- API Endpoints (for future frontend JS fetch calls) ---

@app.route("/api/summary")
def api_summary():
    """JSON endpoint for dashboard data."""
    if not azure_client:
        return jsonify({"error": "Azure credentials not configured"}), 503
    try:
        return jsonify(azure_client.get_dashboard_summary())
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/alerts")
def api_alerts():
    """JSON endpoint for security alerts."""
    if not azure_client:
        return jsonify({"error": "Azure credentials not configured"}), 503
    try:
        return jsonify(azure_client.get_security_alerts())
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/activity")
def api_activity():
    """JSON endpoint for activity log."""
    if not azure_client:
        return jsonify({"error": "Azure credentials not configured"}), 503
    try:
        return jsonify(azure_client.query_activity_log())
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/health")
def health():
    """Health check endpoint for Kubernetes probes."""
    return jsonify({"status": "healthy", "service": "azure-security-dashboard"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=os.getenv("FLASK_DEBUG", "0") == "1")
