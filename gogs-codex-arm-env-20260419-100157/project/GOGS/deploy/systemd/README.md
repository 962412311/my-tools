# ARM Linux systemd 模板

这组模板用于 ARM Linux 原生部署场景，默认假设运行目录为：

```text
/userdata/GOGS/
├── backend/
│   ├── GrabSystem
│   ├── start.sh
│   ├── config/config.ini
│   ├── config/mediamtx.yml
│   ├── logs/
│   ├── data/
│   └── web/
└── frontend/
    └── dist/
```

## 启动顺序

推荐顺序：
1. `mysql.service`
2. `mediamtx.service`
3. `grab-system.service`
4. `nginx.service` 或其他前端静态文件服务

其中：
- `grab-system.service` 依赖 `mysql.service` 和 `mediamtx.service`
- 前端是独立站点，不强依赖 systemd 模板；如需系统服务托管，可直接使用 nginx 或 caddy

## 安装步骤

1. 拷贝模板：

```bash
sudo cp deploy/systemd/mediamtx.service /etc/systemd/system/mediamtx.service
sudo cp deploy/systemd/grab-system.service /etc/systemd/system/grab-system.service
```

2. 将 `__RUN_USER__` 替换为实际运行用户，例如 `root`：

```bash
sudo sed -i 's/__RUN_USER__/root/g' /etc/systemd/system/mediamtx.service
sudo sed -i 's/__RUN_USER__/root/g' /etc/systemd/system/grab-system.service
```

3. 重载并启用：

```bash
sudo systemctl daemon-reload
sudo systemctl enable mediamtx.service
sudo systemctl enable grab-system.service
sudo systemctl start mediamtx.service
sudo systemctl start grab-system.service
```

## 验证

```bash
systemctl status mediamtx.service
systemctl status grab-system.service
journalctl -u grab-system.service -f
```

## 调整项

- 如果运行目录不是 `/userdata/GOGS`，修改两个模板中的 `WorkingDirectory`、`ExecStart` 和配置路径。
- 如果 MySQL 服务名不是 `mysql.service`，同步修改 `grab-system.service` 的 `After=`.
