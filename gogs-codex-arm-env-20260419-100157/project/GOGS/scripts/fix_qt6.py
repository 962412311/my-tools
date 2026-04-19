#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Qt6 兼容性修复脚本
"""

import re
import sys
from pathlib import Path

def fix_material_history_manager():
    """修复 MaterialHistoryManager.cpp"""
    file_path = Path("backend/src/service/MaterialHistoryManager.cpp")
    
    if not file_path.exists():
        print(f"文件不存在: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    
    # 1. 替换 addValue 为 bindValue
    content = content.replace('query.addValue(', 'query.bindValue(')
    
    # 2. 移除 QTextStream::setCodec (Qt6 中已移除)
    content = content.replace('stream.setCodec("UTF-8");', '// Qt6: setCodec removed, UTF-8 is default')
    
    # 3. 添加缺少的头文件
    if '#include <QJsonDocument>' not in content:
        content = content.replace(
            '#include <QDebug>',
            '#include <QDebug>\n#include <QJsonDocument>\n#include <QJsonArray>\n#include <QJsonObject>'
        )
    
    file_path.write_text(content, encoding='utf-8')
    print(f"✅ 已修复: {file_path}")
    return True

def fix_application_cpp():
    """修复 Application.cpp"""
    file_path = Path("backend/src/core/Application.cpp")
    
    if not file_path.exists():
        print(f"文件不存在: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    
    # 替换 QScopedPointer 的 reset(new ...) 为 std::make_unique
    content = re.sub(
        r'(\w+)\.reset\(new (\w+)\(([^)]*)\)\);',
        r'\1 = std::make_unique<\2>(\3);',
        content
    )
    
    # 替换 .data() 为 .get()
    content = content.replace('.data()', '.get()')
    
    file_path.write_text(content, encoding='utf-8')
    print(f"✅ 已修复: {file_path}")
    return True

def fix_point_cloud_processor():
    """修复 PointCloudProcessor.cpp"""
    file_path = Path("backend/src/processing/pcl/PointCloudProcessor.cpp")
    
    if not file_path.exists():
        print(f"文件不存在: {file_path}")
        return False
    
    content = file_path.read_text(encoding='utf-8')
    
    # 检查文件是否完整
    if content.count('{') != content.count('}'):
        print(f"⚠️ 文件括号不匹配，可能需要手动修复: {file_path}")
        return False
    
    file_path.write_text(content, encoding='utf-8')
    print(f"✅ 已检查: {file_path}")
    return True

def main():
    print("开始修复 Qt6 兼容性问题...\n")
    
    results = []
    results.append(fix_material_history_manager())
    results.append(fix_application_cpp())
    results.append(fix_point_cloud_processor())
    
    print("\n" + "="*50)
    if all(results):
        print("✅ 所有文件修复成功！")
        return 0
    else:
        print("⚠️ 部分文件修复失败，请检查上面的输出")
        return 1

if __name__ == "__main__":
    sys.exit(main())
