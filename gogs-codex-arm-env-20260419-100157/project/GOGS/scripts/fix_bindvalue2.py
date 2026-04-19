#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复 Qt6 bindValue 调用 - 添加索引参数
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
    
    # 查找所有 query.prepare(...) 后的 bindValue 调用
    # 模式：查找 prepare 语句，然后替换其后的 bindValue 调用
    
    lines = content.split('\n')
    new_lines = []
    in_prepare_block = False
    bind_index = 0
    
    for line in lines:
        # 检测 prepare 语句
        if 'query.prepare(' in line and ');' in line:
            in_prepare_block = True
            bind_index = 0
            new_lines.append(line)
            continue
        
        # 如果在 prepare 块中，且遇到 bindValue 调用
        if in_prepare_block and 'query.bindValue(' in line:
            bind_index += 1
            # 替换 query.bindValue(value) 为 query.bindValue(index, value)
            # 使用正则表达式匹配
            pattern = r'query\.bindValue\(([^)]+)\);'
            replacement = f'query.bindValue({bind_index}, \\1);'
            line = re.sub(pattern, replacement, line)
            new_lines.append(line)
            continue
        
        # 如果遇到 exec 或其他语句，结束 prepare 块
        if in_prepare_block and ('query.exec()' in line or 'return' in line or line.strip().startswith('if')):
            in_prepare_block = False
        
        new_lines.append(line)
    
    content = '\n'.join(new_lines)
    
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
