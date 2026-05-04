"""Entity and relation extraction via DeepSeek API."""

import json
import logging
from typing import Any

from openai import OpenAI

from graphrag.config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL

logger = logging.getLogger(__name__)

EXTRACTION_SYSTEM_PROMPT = """你是一个知识图谱实体和关系提取器。从用户提供的文本中提取实体和关系。

## 实体类型
- entity: 具体的人物、角色
- concept: 抽象概念、想法、主题
- event: 发生过的事件
- technology: 技术、工具、框架

## 关系类型
- is_a: 实体是另一个的子类/实例
- depends_on: 一个实体依赖于另一个
- created_by: 实体由谁创建
- related_to: 一般关联
- contradicts: 互相矛盾
- extends: 扩展/继承

## 输出格式
始终以 JSON 格式返回，不要有任何其他文字：
{
  "entities": [
    {"name": "实体名", "type": "entity|concept|event|technology", "description": "简短描述", "confidence": 0.95}
  ],
  "relations": [
    {"src": "源实体", "dst": "目标实体", "relation_type": "is_a|depends_on|...", "description": "关系说明", "confidence": 0.9}
  ]
}
"""


class EntityRelationExtractor:
    """Extracts entities and relations from text using DeepSeek API."""

    def __init__(self) -> None:
        if not DEEPSEEK_API_KEY:
            raise ValueError(
                "DEEPSEEK_API_KEY not set. Export it or add to ~/.hermes/.env"
            )
        self.client = OpenAI(
            api_key=DEEPSEEK_API_KEY,
            base_url=DEEPSEEK_BASE_URL,
        )
        self.model = DEEPSEEK_MODEL

    def extract(self, text: str) -> dict[str, Any]:
        """Extract entities and relations from a single text block."""
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": EXTRACTION_SYSTEM_PROMPT},
                    {"role": "user", "content": text},
                ],
                temperature=0.1,
                max_tokens=4096,
            )
            raw = response.choices[0].message.content
            return self._parse_response(raw)
        except Exception:
            logger.exception("Extraction failed for text of length %d.", len(text))
            return {"entities": [], "relations": []}

    def extract_batch(self, texts: list[str]) -> list[dict[str, Any]]:
        """Extract entities and relations from multiple text blocks."""
        results: list[dict[str, Any]] = []
        for i, text in enumerate(texts):
            if not text.strip():
                results.append({"entities": [], "relations": []})
                continue
            logger.info("Extracting from batch item %d/%d...", i + 1, len(texts))
            results.append(self.extract(text))
        return results

    @staticmethod
    def _parse_response(raw: str | None) -> dict[str, Any]:
        if not raw:
            return {"entities": [], "relations": []}
        raw = raw.strip()
        # Strip markdown code fences if present
        if raw.startswith("```"):
            lines = raw.split("\n")
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].strip() == "```":
                lines = lines[:-1]
            raw = "\n".join(lines)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            logger.warning("Failed to parse JSON from response: %.200s...", raw)
            return {"entities": [], "relations": []}
