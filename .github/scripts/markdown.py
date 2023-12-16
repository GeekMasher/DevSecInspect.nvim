import os
import argparse
import yaml

parser = argparse.ArgumentParser("markdown")
parser.add_argument("-s", "--summary", action="store_true")
parser.add_argument("-p", "--path", type=str, default="README.md")
parser.add_argument("-t", "--tools", type=str, default="./tools/tools.yml")


def replaceMarkdownLocation(
    markdown: str, data: str, placeholder: str = "tools"
) -> str:
    start_key = f"<!-- GENERATE: {placeholder} -->"
    end_key = "<!-- GENERATE-END -->"

    start = markdown.find(start_key)
    end = markdown.find(end_key)

    # replace between start and end the data
    return markdown[: start + len(start_key)] + "\n\n" + data + "\n" + markdown[end:]


def generateSummary(tools: dict) -> str:
    markdown = ""

    for key, tool in tools.get("tools", {}).items():
        if url := tool.get("url"):
            markdown += f"- [{tool.get('name', key)}]({url}) ({tool.get('type')})\n"
        else:
            markdown += f"- {tool.get('name', key)} ({tool.get('type')})\n"

    return markdown


def generateTools(tools: dict) -> str:
    markdown = ""

    for key, tool in tools.get("tools", {}).items():
        if url := tool.get("url"):
            markdown += f"## [{tool.get('name', key)}]({url})\n\n"
        else:
            markdown += f"## {tool.get('name', key)}\n\n"

        if description := tool.get("description"):
            markdown += f"{description}\n\n"

        if ttype := tool.get("type"):
            markdown += f"**Type:** {ttype}\n\n"

        if langs := tool.get("languages"):
            markdown += f"**Languages:**\n\n"
            for lang in langs:
                markdown += f"- {lang}\n"
        markdown += "\n"

    return markdown


if __name__ == "__main__":
    args = parser.parse_args()

    if not os.path.exists(args.path):
        raise FileNotFoundError(f"File '{path}' not found")

    # get the markdown
    with open(args.path, "r") as f:
        markdown = f.read()

    with open(args.tools, "r") as f:
        tools = yaml.safe_load(f)

    tools["tools"] = dict(sorted(tools["tools"].items()))

    if args.summary:
        data = generateSummary(tools)
    else:
        data = generateTools(tools)

    # replace the markdown
    markdown = replaceMarkdownLocation(markdown, data)

    with open(args.path, "w") as f:
        f.write(markdown)
