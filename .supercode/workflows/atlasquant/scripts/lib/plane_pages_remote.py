"""
Plane Pages helpers executed on the Plane API container via Django ORM.

Used by migrate-docs-to-plane-pages.sh and plane-pages.sh over SSH.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

# Django setup when run via manage.py shell
from django.contrib.auth import get_user_model
from plane.db.models import Page, Project, ProjectPage


def _project() -> Project:
    project_id = os.environ.get("PLANE_PROJECT_ID")
    if project_id:
        return Project.objects.get(id=project_id)
    return Project.objects.get(identifier=os.environ.get("PLANE_PROJECT_IDENTIFIER", "ATLASQUANT"))


def _owner():
    email = os.environ.get("PLANE_PAGES_OWNER_EMAIL", "naveroot@gmail.com")
    return get_user_model().objects.get(email=email)


def _link_page(project: Project, page: Page, user) -> None:
    if ProjectPage.objects.filter(project=project, page=page).exists():
        return
    ProjectPage.objects.create(
        project=project,
        page=page,
        workspace=project.workspace,
        created_by=user,
    )


def _ensure_page(
    *,
    project: Project,
    user,
    name: str,
    description_html: str,
    external_id: str,
    parent: Page | None,
) -> Page:
    existing = Page.objects.filter(
        workspace=project.workspace,
        external_id=external_id,
        external_source="atlasquant-docs",
    ).first()

    if existing:
        existing.name = name
        existing.description_html = description_html
        existing.parent = parent
        existing.save(update_fields=["name", "description_html", "parent", "updated_at"])
        _link_page(project, existing, user)
        return existing

    page = Page.objects.create(
        name=name,
        workspace=project.workspace,
        owned_by=user,
        parent=parent,
        description_html=description_html,
        external_id=external_id,
        external_source="atlasquant-docs",
    )
    _link_page(project, page, user)
    return page


def migrate_from_bundle(bundle: dict) -> dict:
    """Create/update pages from {files: {path: {name, html}}, tree: nested dict}."""
    project = _project()
    user = _owner()
    created: dict[str, str] = {}

    def walk(node: dict, parent: Page | None, prefix: str) -> None:
        for key, value in sorted(node.items()):
            if key == "__files__":
                for rel_path, meta in sorted(value.items()):
                    page = _ensure_page(
                        project=project,
                        user=user,
                        name=meta["name"],
                        description_html=meta["html"],
                        external_id=rel_path,
                        parent=parent,
                    )
                    created[rel_path] = str(page.id)
                continue

            folder_path = f"{prefix}/{key}" if prefix else key
            folder = _ensure_page(
                project=project,
                user=user,
                name=key.replace("-", " ").title(),
                description_html=f"<p>{key}/</p>",
                external_id=folder_path,
                parent=parent,
            )
            created[folder_path] = str(folder.id)
            walk(value, folder, folder_path)

    walk(bundle["tree"], None, "")
    for rel_path, meta in bundle.get("root_files", {}).items():
        page = _ensure_page(
            project=project,
            user=user,
            name=meta["name"],
            description_html=meta["html"],
            external_id=rel_path,
            parent=None,
        )
        created[rel_path] = str(page.id)

    return {
        "project_id": str(project.id),
        "workspace": project.workspace.slug,
        "pages": created,
    }


def get_page_text(external_id: str) -> dict:
    project = _project()
    page = Page.objects.get(
        workspace=project.workspace,
        external_id=external_id,
        external_source="atlasquant-docs",
    )
    return {
        "id": str(page.id),
        "name": page.name,
        "external_id": external_id,
        "description_stripped": page.description_stripped or "",
        "description_html": page.description_html or "",
    }


def list_pages() -> list[dict]:
    project = _project()
    pages = Page.objects.filter(
        workspace=project.workspace,
        external_source="atlasquant-docs",
    ).order_by("created_at")
    return [
        {
            "id": str(p.id),
            "name": p.name,
            "external_id": p.external_id,
            "parent_id": str(p.parent_id) if p.parent_id else None,
        }
        for p in pages
    ]


def upsert_page(external_id: str, name: str, description_html: str, parent_external_id: str | None) -> dict:
    project = _project()
    user = _owner()
    parent = None
    if parent_external_id:
        parent = Page.objects.get(
            workspace=project.workspace,
            external_id=parent_external_id,
            external_source="atlasquant-docs",
        )
    page = _ensure_page(
        project=project,
        user=user,
        name=name,
        description_html=description_html,
        external_id=external_id,
        parent=parent,
    )
    return {"id": str(page.id), "external_id": external_id, "name": page.name}


def main() -> None:
    cmd = sys.argv[1] if len(sys.argv) > 1 else "help"
    if cmd == "migrate":
        bundle = json.load(sys.stdin)
        print(json.dumps(migrate_from_bundle(bundle)))
    elif cmd == "get":
        print(json.dumps(get_page_text(sys.argv[2])))
    elif cmd == "list":
        print(json.dumps(list_pages()))
    elif cmd == "upsert":
        payload = json.load(sys.stdin)
        print(json.dumps(upsert_page(**payload)))
    else:
        print(json.dumps({"error": f"unknown command: {cmd}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
