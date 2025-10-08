# OCB Docker 镜像

该仓库用于构建一个**纯净的 Odoo Community Backports (OCB)** Docker 镜像，基于官方 `odoo:18.0`，不包含任何私有代码或自定义依赖。

## 特性

- 多阶段构建，仅从 OCA 官方仓库获取 OCB 源码；
- 安装 OCB 自带的 Python 依赖，避免引入额外 requirements；
- 使用官方镜像的运行时入口，保持行为一致。

## 构建镜像

```bash
# 如本地存在代理变量，建议构建前显式清空
# docker build --build-arg http_proxy= --build-arg https_proxy= -t laofahai01/odoo-ocb:18.0 .
docker build -t laofahai01/odoo-ocb:18.0 .
```

可选构建参数：

- `OCB_REPO`：OCB 仓库地址，默认 `https://github.com/OCA/OCB.git`
- `OCB_REF`：Git 分支或标签，默认 `18.0`
- `OCB_COMMIT`：具体提交哈希，可选；设置时会优先生效
- `OCB_ARCHIVE_URL`：用于下载 tarball 的基础 URL，默认 `https://github.com/OCA/OCB/archive`

> 构建阶段已经将 `http_proxy`/`https_proxy` 等变量清空，确保不会访问到宿主机的本地代理。如需自定义代理，可在构建时通过 `--build-arg` 传入。

## 运行容器

```bash
docker run --rm -p 8069:8069 laofahai01/odoo-ocb:18.0
```

如需持久化数据，可挂载 `/var/lib/odoo`。

## 推送流程

```bash
docker login
docker push laofahai01/odoo-ocb:18.0
```

按需添加其他标签（例如 `latest`、`18.0-20241001` 等）。

## 许可说明

OCB 基于 AGPL-3.0 许可发布。构建和分发镜像时，请遵守该许可条款，并向最终用户提供源代码获取途径。
