"""Static URL configuration for the start-of-day checklist.

Each entry is a dict with "label" and "url" keys. An empty list renders as
"[url TBD]" in the checklist prompt.
"""

from typing import Final, TypedDict


class UrlEntry(TypedDict):
    label: str
    url: str


GITLAB_MR_URLS: Final[list[UrlEntry]] = [
    {"label": "Chatlayer Monorepo",                  "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/chatlayer/chatlayer/-/merge_requests"},
    {"label": "Chatlayer Infrastructure",   "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/chatlayer/chatlayer-infrastructure/-/merge_requests"},
    {"label": "Chatlayer App Integrations",           "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/chatlayer/app-integrations/-/merge_requests"},
    {"label": "Generative AI",              "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/chatlayer/chatlayer-nlp/-/merge_requests"},
    {"label": "AI Agents MFE",  "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/agentic_conversations/agentic-conversations-mfe/-/merge_requests"},
    {"label": "AI Agents Backend",      "url": "https://gitlab.com/sinch/sinch-projects/applications/teams/agentic_conversations/agentic-conversations/-/merge_requests"},
]

JIRA_BOARD_URLS: Final[list[UrlEntry]] = [
    {"label": "Chatlayer Product Sprint board", "url": "https://messagemedia.atlassian.net/jira/software/c/projects/CHAT/boards/1573"},
    {"label": "Chatlayer Support Board", "url": "https://messagemedia.atlassian.net/jira/software/c/projects/CHAT/boards/1439"},
    {"label": "Generative AI Sprint Board", "url": "https://messagemedia.atlassian.net/jira/software/c/projects/GAI/boards/644"},
    {"label": "AI Agents Sprint Board", "url": "https://messagemedia.atlassian.net/jira/software/c/projects/AGNT/boards/1736"}
]

DATADOG_DASHBOARD_URLS: Final[list[UrlEntry]] = [
    {"label": "Chatlayer Datadog Bot Engine Dashboard", "url": "https://app.datadoghq.eu/dashboard/2yw-9zd-nxh/nlp-genai-dashboard?fromUser=false&refresh_mode=sliding&from_ts=1781508527560&to_ts=1781512127560&live=true"},
    {"label": "Intelligence Team NLP Dashboard", "url": "https://app.datadoghq.eu/dashboard/2yw-9zd-nxh/nlp-genai-dashboard?fromUser=false&refresh_mode=sliding&from_ts=1781508527560&to_ts=1781512127560&live=true"},
]
INCIDENTS_URLS: Final[list[UrlEntry]] = [
    {"label": "Chatlayer Incidents", "url": "https://sinchenterprise.atlassian.net/issues/?filter=21774"},
]
COST_ANALYSIS_URLS: Final[list[UrlEntry]] = [
    {"label": "Chatlayer MongoDB Billing", "url": "https://cloud.mongodb.com/v2#org/5c177fd1014b7673784050b4/billing/overview"},
    {"label": "Temporal Billing", "url": "https://cloud.temporal.io/billing/invoices"},
]
SECURITY_URLS: Final[list[UrlEntry]] = [
    {"label": "Snyk Projects", "url": "https://app.snyk.io/org/saas-chatlayer-platform/projects"},
    {"label": "Wiz Projects", "url": "https://app.wiz.io/org/saas-chatlayer-platform/projects"},
]
