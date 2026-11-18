// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title LogbookAlat: on-chain loan log for IoT lab tools.
/// @notice Borrowers are known only by wallet address: on-chain data is public and permanent, so no names or student IDs.
contract LogbookAlat {
    struct Alat {
        string nama;   // e.g. "ESP32-S3 N16R8 #1"
        bool tersedia; // false while the tool is lent out
        bool aktif;    // false once the admin retires the tool
    }

    struct Peminjaman {
        uint256 alatId;
        address peminjam;
        uint256 waktuPinjam;
        uint256 waktuKembali; // 0 while the tool has not been returned
    }

    /// The lab admin: the wallet that deployed the contract.
    address public immutable admin;

    Alat[] private daftarAlat;
    Peminjaman[] private daftarPeminjaman;

    event AlatDitambah(uint256 indexed alatId, string nama);
    event AlatDiubah(uint256 indexed alatId, string nama, bool aktif);
    event Dipinjam(uint256 indexed id, uint256 indexed alatId, address indexed peminjam);
    event Dikembalikan(uint256 indexed id, uint256 indexed alatId, address oleh);

    modifier hanyaAdmin() {
        require(msg.sender == admin, "Bukan admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function tambahAlat(string calldata nama) external hanyaAdmin {
        require(bytes(nama).length > 0, "Nama alat kosong");
        daftarAlat.push(Alat(nama, true, true));
        emit AlatDitambah(daftarAlat.length - 1, nama);
    }

    /// Renames, retires or reactivates a tool. Tools are retired, never removed, so loan history stays intact.
    function ubahAlat(uint256 alatId, string calldata nama, bool aktif) external hanyaAdmin {
        require(alatId < daftarAlat.length, "Alat tidak ada");
        require(bytes(nama).length > 0, "Nama alat kosong");
        Alat storage a = daftarAlat[alatId];
        if (!aktif) {
            require(a.tersedia, "Alat sedang dipinjam");
        }
        a.nama = nama;
        a.aktif = aktif;
        emit AlatDiubah(alatId, nama, aktif);
    }

    function pinjam(uint256 alatId) external {
        require(alatId < daftarAlat.length, "Alat tidak ada");
        Alat storage a = daftarAlat[alatId];
        require(a.aktif, "Alat tidak aktif");
        require(a.tersedia, "Alat sedang dipinjam");
        a.tersedia = false;
        daftarPeminjaman.push(Peminjaman(alatId, msg.sender, block.timestamp, 0));
        emit Dipinjam(daftarPeminjaman.length - 1, alatId, msg.sender);
    }

    /// The borrower returns the tool, or the admin records the return for them.
    function kembalikan(uint256 id) external {
        require(id < daftarPeminjaman.length, "Peminjaman tidak ada");
        Peminjaman storage p = daftarPeminjaman[id];
        require(p.waktuKembali == 0, "Sudah dikembalikan");
        require(msg.sender == p.peminjam || msg.sender == admin, "Bukan peminjam");
        p.waktuKembali = block.timestamp;
        daftarAlat[p.alatId].tersedia = true;
        emit Dikembalikan(id, p.alatId, msg.sender);
    }

    function jumlahAlat() external view returns (uint256) {
        return daftarAlat.length;
    }

    function ambilAlat(uint256 alatId) external view returns (string memory nama, bool tersedia, bool aktif) {
        require(alatId < daftarAlat.length, "Alat tidak ada");
        Alat storage a = daftarAlat[alatId];
        return (a.nama, a.tersedia, a.aktif);
    }

    function jumlahPeminjaman() external view returns (uint256) {
        return daftarPeminjaman.length;
    }

    function ambilPeminjaman(uint256 id)
        external
        view
        returns (uint256 alatId, address peminjam, uint256 waktuPinjam, uint256 waktuKembali)
    {
        require(id < daftarPeminjaman.length, "Peminjaman tidak ada");
        Peminjaman storage p = daftarPeminjaman[id];
        return (p.alatId, p.peminjam, p.waktuPinjam, p.waktuKembali);
    }
}
