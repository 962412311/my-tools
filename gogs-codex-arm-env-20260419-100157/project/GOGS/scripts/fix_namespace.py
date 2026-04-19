#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复命名空间问题 - 移除 GrabSystem 命名空间
"""

import re
from pathlib import Path

def fix_file(file_path):
    """修复单个文件"""
    if not file_path.exists():
        return False
    
    content = file_path.read_text(encoding='utf-8', errors='ignore')
    original = content
    
    # 移除 namespace GrabSystem {
    content = re.sub(r'namespace GrabSystem \{', '', content)
    # 移除 } // namespace GrabSystem
    content = re.sub(r'\} // namespace GrabSystem', '', content)
    # 移除 using namespace GrabSystem;
    content = re.sub(r'using namespace GrabSystem;', '', content)
    # 替换 GrabSystem:: 为 空
    content = content.replace('GrabSystem::', '')
    # 清理多余空行
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    if content != original:
        file_path.write_text(content, encoding='utf-8')
        print(f"✅ {file_path}")
        return True
    return False

def main():
    base = Path("backend")
    files = list((base / "include").rglob("*.h")) + list((base / "src").rglob("*.cpp"))
    
    fixed = 0
    for f in files:
        if fix_file(f):
            fixed += 1
    
    print(f"\n共修复 {fixed} 个文件")

if __name__ == "__main__":
    main()
