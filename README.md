# Docker cleanup and registry GC

Bộ script dọn Docker an toàn cho server có dữ liệu:

- `docker-cleanup.sh`: dọn container đã dừng, image dangling, build cache cũ.
- `registry-gc.sh`: garbage-collect Docker Distribution registry.
- Không dùng `docker system prune --volumes -a -f`.
- Không xóa volume, không xóa toàn bộ image đang có.

## Cài lên server

Chạy với quyền root trên server cần dọn:

```bash
sudo mkdir -p /root/scripts /root/registry

sudo install -m 755 docker-cleanup.sh /root/scripts/docker-cleanup.sh
sudo install -m 755 registry-gc.sh /root/registry/clean-old-image.sh
```

Kiểm tra:

```bash
sudo /bin/bash /root/scripts/docker-cleanup.sh
sudo tail -n 50 /var/log/docker-cleanup.log

sudo /bin/bash /root/registry/clean-old-image.sh
sudo tail -n 100 /var/log/registry-gc.log
```

## Chạy thử registry GC

Mặc định script xóa manifest/blob untagged:

```bash
sudo /bin/bash /root/registry/clean-old-image.sh
```

Nếu registry version hỗ trợ `--dry-run`, chạy thử trước:

```bash
sudo REGISTRY_GC_DRY_RUN=1 /bin/bash /root/registry/clean-old-image.sh
sudo tail -n 100 /var/log/registry-gc.log
```

Nếu container registry không tên `registry_registry.1`:

```bash
sudo REGISTRY_CONTAINER=ten-container /bin/bash /root/registry/clean-old-image.sh
```

## Cron

Xóa các dòng cron cũ nếu có:

```cron
0 0 * * * /usr/bin/docker system prune --volumes -a -f
0 0 * * * /bin/bash /root/registry/clean-old-image.sh
```

## Nguyên tắc an toàn

- `docker-cleanup.sh` chỉ xóa container dừng, image dangling và build cache cũ.
- Không dùng `--volumes` trên server có MySQL, registry hoặc dữ liệu quan trọng.
- Không dùng `-a` nếu không muốn xóa image không được container đang chạy tham chiếu.
- Không chạy registry GC cùng lúc với build/push/deploy.
- Registry GC chạy online vẫn có rủi ro; nếu registry có traffic ghi liên tục, dùng read-only maintenance hoặc dừng registry trong maintenance window.
- Kiểm tra dung lượng ổ đĩa định kỳ:

```bash
df -h /var/lib/docker
docker system df
```

- Nếu build cache vẫn lớn, giảm thời gian giữ cache:

```bash
docker builder prune -f --filter until=72h
```
