#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复 Qt6 bindValue 调用脚本
Qt6 的 bindValue 需要指定占位符索引
"""

import re
from pathlib import Path

def fix_bindvalue_in_file(file_path):
    """修复文件中的 bindValue 调用"""
    
    if not file_path.exists():
        print(f"文件不存在: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    
    # 查找所有 query.prepare(sql) 后的 bindValue 调用
    # 模式：query.bindValue(value); -> query.bindValue(index, value);
    
    # 使用正则表达式查找 prepare 和 exec 之间的 bindValue 调用
    pattern = r'(query\.prepare\([^)]+\);)(.*?)(if \(!query\.exec\(\)\))'
    
    def replace_bindvalues(match):
        prepare_stmt = match.group(1)
        middle_section = match.group(2)
        exec_stmt = match.group(3)
        
        # 在 middle_section 中查找所有 bindValue 调用
        bindvalue_pattern = r'query\.bindValue\(([^;]+)\);'
        bindvalues = re.findall(bindvalue_pattern, middle_section)
        
        # 替换为带索引的 bindValue
        new_middle = middle_section
        for i, arg in enumerate(bindvalues, 1):
            old_pattern = f'query.bindValue({re.escape(arg)});'
            new_stmt = f'query.bindValue({i}, {arg});'
            new_middle = new_middle.replace(old_pattern, new_stmt, 1)
        
        return prepare_stmt + new_middle + exec_stmt
    
    content = re.sub(pattern, replace_bindvalues, content, flags=re.DOTALL)
    
    if content != original_content:
        file_path.write_text(content, encoding='utf-8')
        print(f"✅ 已修复: {file_path}")
        return True
    else:
        print(f"ℹ️ 无需修复: {file_path}")
        return True

def main():
    print("开始修复 bindValue 调用...\n")
    
    file_path = Path("backend/src/service/MaterialHistoryManager.cpp")
    success = fix_bindvalue_in_file(file_path)
    
    print("\n" + "="*50)
    if success:
        print("✅ 修复完成！")
        return 0
    else:
        print("❌ 修复失败")
        return 1

if __name__ == "__main__":
    import sys
    sys.exit(main())
