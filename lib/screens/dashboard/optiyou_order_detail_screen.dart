import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_order_operation_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/models/order_operation_file_model.dart';
import 'package:oy_site/models/order_operation_state_model.dart';
import 'package:url_launcher/url_launcher.dart';

class OptiYouOrderDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final OptiYouOrderOperationItem operationItem;

  const OptiYouOrderDetailScreen({
    super.key,
    required this.currentUser,
    required this.operationItem,
  });

  @override
  State<OptiYouOrderDetailScreen> createState() =>
      _OptiYouOrderDetailScreenState();
}

class _OptiYouOrderDetailScreenState extends State<OptiYouOrderDetailScreen> {
  final SupabaseOrderOperationRepository _operationRepository =
      SupabaseOrderOperationRepository();

  OrderModel get order => widget.operationItem.order;

  OrderOperationStateModel? _operationState;
  final Map<String, OrderOperationFileModel> _operationFiles = {};

  bool _isLoadingOperation = true;
  bool _isSavingOperation = false;

  bool _designCompleted = false;
  bool _productionStarted = false;
  bool _productionCompleted = false;

  bool _qcDesignMatch = false;
  bool _qcMeasurementDone = false;
  bool _qcSurfaceChecked = false;
  bool _qcReadyForDelivery = false;

  bool _packagingCompleted = false;
  bool _orderClosed = false;

  String? _leftDesignStlName;
  String? _rightDesignStlName;
  String? _leftProductionFileName;
  String? _rightProductionFileName;

  final TextEditingController _qualityNoteController = TextEditingController();
  final TextEditingController _shippingTrackingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOperationData();
  }

  @override
  void dispose() {
    _qualityNoteController.dispose();
    _shippingTrackingController.dispose();
    super.dispose();
  }

  Future<void> _loadOperationData() async {
    final orderId = order.orderId;

    if (orderId == null) {
      setState(() => _isLoadingOperation = false);
      return;
    }

    setState(() => _isLoadingOperation = true);

    try {
      final state = await _operationRepository.getStateByOrderId(
        orderId: orderId,
      );

      final files = await _operationRepository.getFilesByOrderId(
        orderId: orderId,
      );

      final effectiveState = state ??
          OrderOperationStateModel.empty(
            orderId: orderId,
            sessionId: order.sessionId,
            patientId: order.patientId,
            assignedUserId: widget.currentUser.userId,
          );

      if (!mounted) return;

      setState(() {
        _operationState = effectiveState;

        _designCompleted = effectiveState.designCompleted;
        _productionStarted = effectiveState.productionStarted;
        _productionCompleted = effectiveState.productionCompleted;

        _qcDesignMatch = effectiveState.qcDesignMatch;
        _qcMeasurementDone = effectiveState.qcMeasurementDone;
        _qcSurfaceChecked = effectiveState.qcSurfaceChecked;
        _qcReadyForDelivery = effectiveState.qcReadyForDelivery;

        _qualityNoteController.text = effectiveState.qcNote ?? '';

        _packagingCompleted = effectiveState.packagingCompleted;
        _shippingTrackingController.text =
            effectiveState.shippingTrackingNo ?? '';

        _orderClosed = effectiveState.orderClosed;

        _operationFiles.clear();
        for (final file in files) {
          _operationFiles[file.fileType] = file;
        }

        _leftDesignStlName =
            _operationFiles[OrderOperationFileTypes.leftDesignStl]?.fileName;
        _rightDesignStlName =
            _operationFiles[OrderOperationFileTypes.rightDesignStl]?.fileName;
        _leftProductionFileName =
            _operationFiles[OrderOperationFileTypes.leftProductionFile]
                ?.fileName;
        _rightProductionFileName =
            _operationFiles[OrderOperationFileTypes.rightProductionFile]
                ?.fileName;

        _isLoadingOperation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingOperation = false);
      _showMessage('Operasyon verileri yüklenemedi: $e');
    }
  }

  Future<void> _persistOperationState() async {
    final orderId = order.orderId;
    final userId = widget.currentUser.userId;

    if (orderId == null) return;

    setState(() => _isSavingOperation = true);

    try {
      final state = OrderOperationStateModel(
        id: _operationState?.id,
        orderId: orderId,
        sessionId: order.sessionId,
        patientId: order.patientId,
        assignedUserId: userId,
        designCompleted: _designCompleted,
        productionStarted: _productionStarted,
        productionCompleted: _productionCompleted,
        qcDesignMatch: _qcDesignMatch,
        qcMeasurementDone: _qcMeasurementDone,
        qcSurfaceChecked: _qcSurfaceChecked,
        qcReadyForDelivery: _qcReadyForDelivery,
        qcNote: _qualityNoteController.text.trim(),
        packagingCompleted: _packagingCompleted,
        shippingTrackingNo: _shippingTrackingController.text.trim(),
        orderClosed: _orderClosed,
      );

      final saved = await _operationRepository.upsertState(state: state);

      if (!mounted) return;

      setState(() {
        _operationState = saved;
        _isSavingOperation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSavingOperation = false);
      _showMessage('Operasyon durumu kaydedilemedi: $e');
    }
  }

  Future<void> _pickAndUploadOperationFile({
    required String title,
    required String fileType,
    required void Function(String fileName) onSelected,
  }) async {
    final orderId = order.orderId;
    final userId = widget.currentUser.userId;

    if (orderId == null || userId == null) {
      _showMessage('Order ID veya kullanıcı ID bulunamadı.');
      return;
    }

    final result = await FilePicker.pickFiles(
      dialogTitle: title,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.path == null) {
      _showMessage('Dosya yolu alınamadı.');
      return;
    }

    try {
      setState(() => _isSavingOperation = true);

      final uploaded = await _operationRepository.uploadOperationFile(
        orderId: orderId,
        sessionId: order.sessionId,
        patientId: order.patientId,
        uploadedByUserId: userId,
        fileType: fileType,
        localFilePath: file.path!,
        fileName: file.name,
      );

      if (!mounted) return;

      setState(() {
        _operationFiles[fileType] = uploaded;
        onSelected(uploaded.fileName ?? file.name);
        _isSavingOperation = false;
      });

      _showMessage('${uploaded.fileName ?? file.name} Storage’a yüklendi.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSavingOperation = false);
      _showMessage('Dosya yüklenemedi: $e');
    }
  }

  Future<void> _downloadOperationFile(String fileType, String label) async {
    final file = _operationFiles[fileType];

    if (file == null) {
      _showMessage('$label için yüklü dosya bulunamadı.');
      return;
    }

    try {
      final url = await _operationRepository.createSignedUrl(file: file);
      final uri = Uri.parse(url);

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Dosya bağlantısı açılamadı.');
      }
    } catch (e) {
      _showMessage('Dosya indirilemedi: $e');
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatMoney(double amount, String currencyCode) {
    return '${amount.toStringAsFixed(2)} $currencyCode';
  }

  String _productLabel(String productType) {
    switch (productType) {
      case 'insole':
        return 'Tabanlık';
      case 'sports_insole':
        return 'Spor Tabanlık';
      case 'sandal':
        return 'Sandalet';
      default:
        return productType;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case OrderStatuses.pending:
        return 'Beklemede';
      case OrderStatuses.designing:
        return 'Tasarımda';
      case OrderStatuses.production:
        return 'Üretimde';
      case OrderStatuses.shipped:
        return 'Kargoda';
      case OrderStatuses.delivered:
        return 'Teslim Edildi';
      case OrderStatuses.cancelled:
        return 'İptal';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case OrderStatuses.pending:
        return Colors.orange;
      case OrderStatuses.designing:
        return Colors.deepPurple;
      case OrderStatuses.production:
        return Colors.blue;
      case OrderStatuses.shipped:
        return Colors.teal;
      case OrderStatuses.delivered:
        return Colors.green;
      case OrderStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openDesignForm() {
    _showMessage('Ortez tasarım formu görüntüleme akışı sonra bağlanacak.');
  }

  void _downloadPlaceholder(String label) {
    _showMessage('$label indirme akışı sonra bağlanacak.');
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool completed,
    required Widget child,
  }) {
    final color = completed ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              completed ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$index. $title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  completed ? 'Tamamlandı' : 'Bekliyor',
                  style: TextStyle(
                    color: completed
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildUploadedFileRow({
    required String label,
    required String? fileName,
    required VoidCallback onUpload,
    required VoidCallback onDownload,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName == null ? '$label: Dosya yok' : '$label: $fileName',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: 'İndir',
            onPressed: fileName == null ? null : onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Yükle'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDownloadRow({
    required String label,
    required VoidCallback onDownload,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: 'İndir',
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationActionsCard() {
    return _buildSectionCard(
      title: 'İletişim Aksiyonları',
      child: Column(
        children: [
          _buildFullWidthButton(
            icon: Icons.mail_outline,
            label: 'Bilgi Maili Gönder',
            onPressed: () =>
                _showMessage('Bilgi maili gönderme akışı sonra bağlanacak.'),
          ),
          const SizedBox(height: 10),
          _buildFullWidthButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Sipariş Teslim Maili Gönder',
            onPressed: () =>
                _showMessage('Teslim maili gönderme akışı sonra bağlanacak.'),
          ),
          const SizedBox(height: 10),
          _buildFullWidthButton(
            icon: Icons.rate_review_outlined,
            label: 'Memnuniyet Anketi Gönder',
            onPressed: () =>
                _showMessage('Memnuniyet anketi akışı sonra bağlanacak.'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildDesignStepCard() {
    return _buildOperationCard(
      index: 1,
      title: 'Tasarım Hazırlığı',
      description:
          'Ölçüm verileri incelenir, gerekli girdi dosyaları indirilir ve ürün tasarım dosyaları yüklenir.',
      icon: Icons.design_services_outlined,
      completed: _designCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.assignment_outlined,
                label: 'Tasarım Formunu Görüntüle',
                onPressed: _openDesignForm,
              ),
              _buildActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analiz Raporunu Görüntüle',
                onPressed: () =>
                    _showMessage('Analiz raporu görüntüleme akışı sonra bağlanacak.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Girdi Dosyaları',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildInputDownloadRow(
            label: 'Sol ayak 3D scan STL',
            onDownload: () => _downloadPlaceholder('Sol ayak 3D scan STL'),
          ),
          _buildInputDownloadRow(
            label: 'Sağ ayak 3D scan STL',
            onDownload: () => _downloadPlaceholder('Sağ ayak 3D scan STL'),
          ),
          _buildInputDownloadRow(
            label: 'Basınç kayıtları',
            onDownload: () => _downloadPlaceholder('Basınç kayıtları'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tasarım Çıktıları',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildUploadedFileRow(
            label: 'Sol ürün tasarım STL',
            fileName: _leftDesignStlName,
            onUpload: () => _pickAndUploadOperationFile(
              title: 'Sol ürün tasarım STL seç',
              fileType: OrderOperationFileTypes.leftDesignStl,
              onSelected: (name) => _leftDesignStlName = name,
            ),
            onDownload: () => _downloadOperationFile(
              OrderOperationFileTypes.leftDesignStl,
              'Sol ürün tasarım STL',
            ),
          ),
          _buildUploadedFileRow(
            label: 'Sağ ürün tasarım STL',
            fileName: _rightDesignStlName,
            onUpload: () => _pickAndUploadOperationFile(
              title: 'Sağ ürün tasarım STL seç',
              fileType: OrderOperationFileTypes.rightDesignStl,
              onSelected: (name) => _rightDesignStlName = name,
            ),
            onDownload: () => _downloadOperationFile(
              OrderOperationFileTypes.rightDesignStl,
              'Sağ ürün tasarım STL',
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _designCompleted,
            onChanged: (v) async {
              setState(() => _designCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Tasarım tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildProductionStepCard() {
    return _buildOperationCard(
      index: 2,
      title: 'Üretim Hazırlığı ve Üretim',
      description:
          'Üretim dosyaları yüklenir. CNC için G-code, 3D baskı için slice dosyası veya ürüne özel üretim dosyası kullanılabilir.',
      icon: Icons.precision_manufacturing_outlined,
      completed: _productionCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUploadedFileRow(
            label: 'Sol ürün üretim dosyası',
            fileName: _leftProductionFileName,
            onUpload: () => _pickAndUploadOperationFile(
              title: 'Sol ürün üretim dosyası seç',
              fileType: OrderOperationFileTypes.leftProductionFile,
              onSelected: (name) => _leftProductionFileName = name,
            ),
            onDownload: () => _downloadOperationFile(
              OrderOperationFileTypes.leftProductionFile,
              'Sol ürün üretim dosyası',
            ),
          ),
          _buildUploadedFileRow(
            label: 'Sağ ürün üretim dosyası',
            fileName: _rightProductionFileName,
            onUpload: () => _pickAndUploadOperationFile(
              title: 'Sağ ürün üretim dosyası seç',
              fileType: OrderOperationFileTypes.rightProductionFile,
              onSelected: (name) => _rightProductionFileName = name,
            ),
            onDownload: () => _downloadOperationFile(
              OrderOperationFileTypes.rightProductionFile,
              'Sağ ürün üretim dosyası',
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _productionStarted,
            onChanged: (v) async {
              setState(() => _productionStarted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Üretim başladı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _productionCompleted,
            onChanged: (v) async {
              setState(() => _productionCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Üretim tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityControlCard() {
    final completed = _qcDesignMatch &&
        _qcMeasurementDone &&
        _qcSurfaceChecked &&
        _qcReadyForDelivery;

    return _buildOperationCard(
      index: 3,
      title: 'Kalite Kontrol',
      description:
          'Ürünün tasarım, ölçü, yüzey ve teslimata uygunluk kontrolleri yapılır.',
      icon: Icons.fact_check_outlined,
      completed: completed,
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcDesignMatch,
            onChanged: (v) async {
              setState(() => _qcDesignMatch = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ürün dosya/tasarım ile uyumlu'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcMeasurementDone,
            onChanged: (v) async {
              setState(() => _qcMeasurementDone = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ölçü ve form kontrolü yapıldı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcSurfaceChecked,
            onChanged: (v) async {
              setState(() => _qcSurfaceChecked = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Yüzey / kenar kontrolü yapıldı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcReadyForDelivery,
            onChanged: (v) async {
              setState(() => _qcReadyForDelivery = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ürün teslimata uygun'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qualityNoteController,
            maxLines: 3,
            onEditingComplete: _persistOperationState,
            decoration: const InputDecoration(
              labelText: 'Kalite kontrol notu',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingShippingCard() {
    final completed =
        _packagingCompleted && _shippingTrackingController.text.trim().isNotEmpty;

    return _buildOperationCard(
      index: 4,
      title: 'Paketleme ve Kargo',
      description:
          'Paketleme tamamlanır ve kargo takip bilgisi siparişe eklenir.',
      icon: Icons.local_shipping_outlined,
      completed: completed,
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _packagingCompleted,
            onChanged: (v) async {
              setState(() => _packagingCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Paketleme tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _shippingTrackingController,
            onChanged: (_) => setState(() {}),
            onEditingComplete: _persistOperationState,
            decoration: const InputDecoration(
              labelText: 'Kargo takip numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: completed ? _persistOperationState : null,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Kargoya Verildi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseOperationCard() {
    return _buildOperationCard(
      index: 5,
      title: 'Operasyonu Kapat',
      description:
          'Sipariş teslim ve operasyon kapanış kontrolleri tamamlandıktan sonra süreç kapatılır.',
      icon: Icons.check_circle_outline,
      completed: _orderClosed,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _orderClosed,
        onChanged: (v) async {
          setState(() => _orderClosed = v ?? false);
          await _persistOperationState();
        },
        title: const Text('Operasyon kapatıldı'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOperation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final statusColor = _statusColor(order.orderStatus);
    final priorityColor = _priorityColor(widget.operationItem.priorityLabel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operasyon Sipariş Detayı'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          if (_isSavingOperation) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: statusColor.withOpacity(0.12),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 34,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.orderNo,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_productLabel(order.productType)} • ${widget.operationItem.expertName}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Operasyon kullanıcısı: ${widget.currentUser.displayName}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(order.orderStatus),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Öncelik: ${widget.operationItem.priorityLabel}',
                                    style: TextStyle(
                                      color: priorityColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildSectionCard(
                                  title: 'Sipariş Referans Bilgileri',
                                  child: Column(
                                    children: [
                                      _buildKeyValueRow(
                                        'Order ID',
                                        order.orderId?.toString() ?? '—',
                                      ),
                                      _buildKeyValueRow(
                                        'Session ID',
                                        order.sessionId.toString(),
                                      ),
                                      _buildKeyValueRow(
                                        'Patient ID',
                                        order.patientId.toString(),
                                      ),
                                      _buildKeyValueRow(
                                        'Clinic',
                                        widget.operationItem.clinicName,
                                      ),
                                      _buildKeyValueRow(
                                        'Expert',
                                        widget.operationItem.expertName,
                                      ),
                                      _buildKeyValueRow(
                                        'Assigned OptiYou User ID',
                                        order.assignedOptityouUserId
                                                ?.toString() ??
                                            '—',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSectionCard(
                                  title: 'Tarih ve Fiyat Bilgileri',
                                  child: Column(
                                    children: [
                                      _buildKeyValueRow(
                                        'Sipariş Tarihi',
                                        _formatDate(order.orderedAt),
                                      ),
                                      _buildKeyValueRow(
                                        'Kargo Tarihi',
                                        _formatDate(order.shippedAt),
                                      ),
                                      _buildKeyValueRow(
                                        'Teslim Tarihi',
                                        _formatDate(order.deliveredAt),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildKeyValueRow(
                                        'Brüt Tutar',
                                        _formatMoney(
                                          order.grossAmount,
                                          order.currencyCode,
                                        ),
                                      ),
                                      _buildKeyValueRow(
                                        'İndirim',
                                        _formatMoney(
                                          order.discountAmount,
                                          order.currencyCode,
                                        ),
                                      ),
                                      _buildKeyValueRow(
                                        'Net Tutar',
                                        _formatMoney(
                                          order.netAmount,
                                          order.currencyCode,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCommunicationActionsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildSectionCard(
                              title: 'Üretim Operasyon Akışı',
                              child: Column(
                                children: [
                                  _buildDesignStepCard(),
                                  _buildProductionStepCard(),
                                  _buildQualityControlCard(),
                                  _buildPackagingShippingCard(),
                                  _buildCloseOperationCard(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}