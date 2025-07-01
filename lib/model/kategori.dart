class KategoriModel {
int? idKategori;
String? namaKategori;
String? deskripsiKategori;
String? createdAt;
String? updatedAt;
KategoriModel(
{this.idKategori,
this.namaKategori,
this.deskripsiKategori,
this.createdAt,
this.updatedAt});
KategoriModel.fromJson(Map<String, dynamic> json) {
idKategori = json['id_kategori'];
namaKategori = json['nama_kategori'];
deskripsiKategori = json['deskripsi_kategori'];
createdAt = json['created_at'];
updatedAt = json['updated_at'];
}
Map<String, dynamic> toJson() {
final Map<String, dynamic> data = <String, dynamic>{};
data['id_kategori'] = idKategori;
data['nama_kategori'] = namaKategori;
data['deskripsi_kategori'] = deskripsiKategori;
data['created_at'] = createdAt;
data['updated_at'] = updatedAt;
return data;
}
}