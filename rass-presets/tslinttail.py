"""TypeScript preset: typescript-language-server + eslint-language-server."""

import os
import shutil

from rassumfrassum.frassum import LspLogic, Server
from rassumfrassum.json import JSON
from rassumfrassum.util import dmerge, info
from typing import cast, Any


def _find_workspace_folder(scope_uri: str) -> dict | None:
    """Find workspace folder by searching for package.json from scopeUri."""
    if not scope_uri.startswith(""):
        return None

    file_path = scope_uri[7:]  # Remove 'file://'
    current_dir = os.path.dirname(file_path)

    while current_dir and current_dir != "/":
        if os.path.exists(os.path.join(current_dir, "package.json")):
            return {
                "uri": f"file://{current_dir}",
                "name": os.path.basename(current_dir),
            }
        parent = os.path.dirname(current_dir)
        if parent == current_dir:  # Reached root
            break
        current_dir = parent

    return None

def _eslint_config(workspace_folder: dict | None = None) -> dict:
    """Return base ESLint configuration."""
    config = {
        # 'probe' which is used in rassumfrassum/.../presets/tslint.py doesn't work for some reason
        "validate": "on",
        "problems": {},
        "rulesCustomizations": [],
        "nodePath": None,
        "experimental": {},
        "codeAction": {
            "disableRuleComment": {
                "enable": True,
                "location": "separateLine",
            },
            "showDocumentation": {"enable": True},
        },
    }
    if workspace_folder:
        config["workspaceFolder"] = workspace_folder
    return config


class TypeScriptLogic(LspLogic):
    """Custom logic for TypeScript-friendly servers."""

    async def on_client_response(
        self,
        method: str,
        request_params: JSON,
        response_payload: JSON,
        is_error: bool,
        server: Server,
    ) -> None:
        """Enrich some workspace/configuration responses for ESLint."""
        if (
            method == "workspace/configuration"
            and not is_error
            and "eslint" in server.name.lower()
        ):
            info("Enriching workspace/configuration ESLint specifically")
            req_items = request_params.get("items", [])
            res_items = cast(list[Any], response_payload)
            if len(res_items) < len(req_items):
                res_items.extend([None] * (len(req_items) - len(res_items)))

            # Enrich each item
            for i, item in enumerate(req_items):
                section = item.get("section", "")
                # Only enrich if section is empty (ESLint config request)
                if section == "":
                    wfolder = _find_workspace_folder(item.get("scopeUri", ""))
                    cfg = _eslint_config(wfolder)

                    # Merge with existing config or replace None
                    if isinstance(res_items[i], dict):
                        res_items[i] = dmerge(res_items[i], cfg)
                    else:
                        res_items[i] = cfg
        elif (
            method == "workspace/configuration"
            and not is_error
            and "tailwindcss" in server.name.lower()
        ):
            info("Enriching /configuration for Tailwindcss specifically")
            req_items = request_params.get("items", [])
            res_items = cast(list[Any], response_payload)
            if len(res_items) < len(req_items):
                res_items.extend([None] * (len(req_items) - len(res_items)))

            for i, item in enumerate(req_items):
                section = item.get("section", "")

                if section == "tailwindCSS":
                    language = {
                        "includeLanguages": {
                            "html": "html",
                            "jsx": "javascriptreact",
                            "tsx": "typescriptreact",
                            "ts": "typescript",
                            "js": "javascript",
                            "css": "css"
                        },
                    }
                    if isinstance(res_items[i], dict):
                        res_items[i] = dmerge(res_items[i], language)
                    else:
                        res_items[i] = language

                # elif section == "editor":
                #     editor = {
                #         "quickSuggestions": {
                #             "strings": True
                #         },
                #     }
                #     if isinstance(res_items[i], dict):
                #         res_items[i] = dmerge(res_items[i], editor)
                #     else:
                #         res_items[i] = editor


        await super().on_client_response(
            method, request_params, response_payload, is_error, server
        )


def servers():
    """Return eslint-language-server."""

    eslint_server = "vscode-eslint-language-server"
    if shutil.which(eslint_server) is None:
        eslint_server = "eslint-language-server"

    return [
        ["typescript-language-server", "--stdio"],
        [eslint_server, "--stdio"],
        ["tailwindcss-language-server", "--stdio"],
    ]


def logic_class():
    """Use custom TypeScriptLogic."""
    return TypeScriptLogic
