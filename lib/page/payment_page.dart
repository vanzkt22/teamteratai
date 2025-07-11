import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentPage extends StatefulWidget {
  final int total;
  final List<dynamic> items;

  const PaymentPage({super.key, required this.total, required this.items});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase = Supabase.instance.client;
  String metodePembayaran = 'Dana';
  bool isProcessing = false;

  Future<void> handlePayment() async {
    final user = supabase.auth.currentUser;
    if (user == null || isProcessing) return;

    setState(() => isProcessing = true);

    try {
      // Simpan transaksi utama
      final transaksiRes = await supabase.from('transactions').insert({
        'user_id': user.id,
        'total_price': widget.total,
        'payment_method': metodePembayaran,
        'status': 'selesai',
      }).select().single();

      final transactionId = transaksiRes['id'];

      // Simpan detail item transaksi
      for (final item in widget.items) {
        await supabase.from('transaction_items').insert({
          'transaction_id': transactionId,
          'product_id': item['product']['id'],
          'quantity': item['quantity'],
          'price': item['product']['price'],
        });
      }

      // Hapus cart user
      await supabase.from('cart').delete().eq('user_id', user.id);

      // Navigasi ke struk
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/receipt',
        (route) => false,
        arguments: {
          'transaction': transaksiRes,
          'items': widget.items,
        },
      );
    } catch (e) {
      debugPrint("Payment error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Gagal memproses pembayaran")),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: _navBar(1),
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: Colors.brown,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Image.asset(
            'assets/bg.jpeg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Metode Pembayaran",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile(
                      title: const Text("Bayar dengan kartu debit"),
                      value: 'Kartu',
                      groupValue: metodePembayaran,
                      onChanged: (val) => setState(() => metodePembayaran = val!),
                    ),
                    RadioListTile(
                      title: const Text("Bayar dengan Dana"),
                      value: 'Dana',
                      groupValue: metodePembayaran,
                      onChanged: (val) => setState(() => metodePembayaran = val!),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Pembayaran",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Rp${widget.total}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : handlePayment,
                        icon: isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(isProcessing ? "Memproses..." : "Bayar Sekarang"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _navBar(int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      backgroundColor: Colors.brown[400],
      selectedItemColor: Colors.white,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacementNamed(context, '/home');
        if (index == 1) Navigator.pushReplacementNamed(context, '/cart');
        if (index == 2) Navigator.pushReplacementNamed(context, '/history');
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.coffee), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.receipt), label: ''),
      ],
    );
  }
}
