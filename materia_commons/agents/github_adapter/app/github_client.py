from github import Github
from github.PullRequest import PullRequest
from github.CheckRun import CheckRun
from config import Config

class GitHubClient:
    def __init__(self, token: str = None):
        self.token = token or Config.GITHUB_ACCESS_TOKEN
        self.gh = Github(self.token)

    def get_pr(self, repo_full_name: str, pr_number: int) -> PullRequest:
        repo = self.gh.get_repo(repo_full_name)
        return repo.get_pull(pr_number)

    def post_comment(self, pr: PullRequest, message: str):
        pr.create_issue_comment(message)

    def approve_pr(self, pr: PullRequest):
        # Requires write access to the repo
        pr.create_review(event="APPROVE", body="✅ Governance passed; transition ratified.")

    def request_changes(self, pr: PullRequest, message: str):
        pr.create_review(event="REQUEST_CHANGES", body=message)

    def create_check_run(
        self,
        repo_full_name: str,
        head_sha: str,
        name: str = "Sigma Governance",
        status: str = "in_progress",
        started_at: str = None,
    ) -> CheckRun:
        repo = self.gh.get_repo(repo_full_name)
        return repo.create_check_run(
            name=name,
            head_sha=head_sha,
            status=status,
            started_at=started_at,
        )

    def update_check_run(
        self,
        repo_full_name: str,
        check_run_id: int,
        status: str = "completed",
        conclusion: str = None,
        completed_at: str = None,
        output: dict = None,
    ) -> CheckRun:
        repo = self.gh.get_repo(repo_full_name)
        check_run = repo.get_check_run(check_run_id)
        return check_run.edit(
            status=status,
            conclusion=conclusion,
            completed_at=completed_at,
            output=output,
        )
