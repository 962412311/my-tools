#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复 Application.cpp 中的 QScopedPointer 语法
"""

from pathlib import Path

def fix_application_cpp():
    """修复 Application.cpp"""
    file_path = Path("backend/src/core/Application.cpp")
    
    if not file_path.exists():
        print(f"文件不存在: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    
    # 1. 替换 .reset(new ...) 为 = std::make_unique<...>(...)
    import re
    content = re.sub(
        r'(\w+)\.reset\(new (\w+)\(([^)]*)\)\);',
        r'\1 = std::make_unique<\2>(\3);',
        content
    )
    
    # 2. 替换 .data() 为 .get()
    content = content.replace('.data()', '.get()')
    
    file_path.write_text(content, encoding='utf-8')
    print(f"✅ 已修复: {file_path}")
    return True

def main():
    print("开始修复 Application.cpp...\n")
    fix_application_cpp()
    print("\n" + "="*50)
    print("✅ 修复完成！")

if __name__ == "__main__":
    main()
