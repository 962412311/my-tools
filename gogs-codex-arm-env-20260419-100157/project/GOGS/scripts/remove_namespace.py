#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
移除 GrabSystem 命名空间脚本
解决 Qt6 moc 的命名空间问题
"""

import re
from pathlib import Path

def remove_namespace_from_file(file_path):
    """从文件中移除 GrabSystem 命名空间"""
    
    if not file_path.exists():
        return False
    
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    
    # 1. 移除 namespace GrabSystem {
    content = re.sub(r'namespace GrabSystem \{', '', content)
    
    # 2. 移除 } // namespace GrabSystem
    content = re.sub(r'\} // namespace GrabSystem', '', content)
    
    # 3. 移除 using namespace GrabSystem;
    content = re.sub(r'using namespace GrabSystem;', '', content)
    
    # 4. 替换 GrabSystem:: 为 空（全局命名空间）
    content = content.replace('GrabSystem::', '')
    
    # 5. 清理多余的空行
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    if content != original_content:
        file_path.write_text(content, encoding='utf-8')
        print(f"✅ 已处理: {file_path}")
        return True
    else:
        print(f"ℹ️ 无需处理: {file_path}")
        return True

def process_directory(directory, extensions):
    """处理目录中的所有文件"""
    for ext in extensions:
        for file_path in Path(directory).rglob(f'*.{ext}'):
            remove_namespace_from_file(file_path)

def main():
    print("开始移除 GrabSystem 命名空间...\n")
    
    backend_dir = Path("backend")
    
    # 处理头文件
    print("处理头文件...")
    process_directory(backend_dir / "include", ['h'])
    
    # 处理源文件
    print("\n处理源文件...")
    process_directory(backend_dir / "src", ['cpp'])
    
    print("\n" + "="*50)
    print("✅ 命名空间移除完成！")
    print("注意：需要手动检查并修复可能的编译错误")

if __name__ == "__main__":
    main()
