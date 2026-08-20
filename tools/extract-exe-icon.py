#!/usr/bin/env python3
"""Windows PE 실행 파일에 박힌 첫 번째 아이콘 그룹을 .ico로 뽑아낸다.

icoutils(wrestool) 없이 동작하도록 표준 라이브러리만 쓴다. KakaoTalk.exe에는
256x256 아이콘이 들어 있어, skin 폴더의 80px PNG를 확대하는 것보다 결과가 선명하다.

사용법:
    python3 tools/extract-exe-icon.py <입력.exe> <출력.ico>
"""

import struct
import sys

RT_ICON = 3
RT_GROUP_ICON = 14


def main(exe_path, ico_path):
    data = open(exe_path, "rb").read()

    pe = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe:pe + 4] != b"PE\0\0":
        sys.exit(f"{exe_path}: PE 헤더를 찾을 수 없다")

    nsec, = struct.unpack_from("<H", data, pe + 6)
    optsz, = struct.unpack_from("<H", data, pe + 20)
    magic, = struct.unpack_from("<H", data, pe + 24)
    # optional header 뒤의 data directory에서 .rsrc 위치를 읽는다 (인덱스 2)
    ddoff = pe + 24 + (96 if magic == 0x10B else 112)
    rsrc_rva, _rsrc_sz = struct.unpack_from("<II", data, ddoff + 2 * 8)

    sections = []
    for i in range(nsec):
        off = pe + 24 + optsz + 40 * i
        va, = struct.unpack_from("<I", data, off + 12)
        raw_size, = struct.unpack_from("<I", data, off + 16)
        raw_ptr, = struct.unpack_from("<I", data, off + 20)
        sections.append((va, raw_size, raw_ptr))

    def rva2off(rva):
        for va, raw_size, raw_ptr in sections:
            if va <= rva < va + raw_size:
                return raw_ptr + (rva - va)
        sys.exit(f"RVA {rva:#x}를 파일 오프셋으로 변환할 수 없다")

    base = rva2off(rsrc_rva)

    def entries(off):
        n_named, n_id = struct.unpack_from("<HH", data, off + 12)
        out = []
        for i in range(n_named + n_id):
            name_or_id, offset = struct.unpack_from("<II", data, off + 16 + 8 * i)
            out.append((name_or_id, offset))
        return out

    def leaves(type_id):
        """해당 리소스 타입의 (리소스 ID, 파일 오프셋, 크기) 목록."""
        for name_or_id, sub in entries(base):
            if name_or_id & 0x80000000 or name_or_id != type_id:
                continue
            for res_id, sub2 in entries(base + (sub & 0x7FFFFFFF)):
                for _lang, sub3 in entries(base + (sub2 & 0x7FFFFFFF)):
                    rva, size = struct.unpack_from("<II", data, base + (sub3 & 0x7FFFFFFF))
                    yield res_id & 0x7FFFFFFF, rva2off(rva), size
            return

    icons = {res_id: (off, size) for res_id, off, size in leaves(RT_ICON)}
    groups = list(leaves(RT_GROUP_ICON))
    if not groups:
        sys.exit(f"{exe_path}: RT_GROUP_ICON 리소스가 없다")

    _gid, goff, _gsize = groups[0]
    count, = struct.unpack_from("<H", data, goff + 4)

    header = bytearray(struct.pack("<HHH", 0, 1, count))  # ICONDIR
    images = []
    image_off = 6 + 16 * count
    for i in range(count):
        entry = goff + 6 + 14 * i
        w, h, colors, _res, planes, bits, size, res_id = struct.unpack_from("<BBBBHHIH", data, entry)
        src_off, _src_size = icons[res_id]
        header += struct.pack("<BBBBHHII", w, h, colors, 0, planes, bits, size, image_off)
        images.append(data[src_off:src_off + size])
        image_off += size

    with open(ico_path, "wb") as f:
        f.write(bytes(header) + b"".join(images))
    print(f"{ico_path}: {count}개 프레임 추출")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
