import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});
  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _mainImages = []; 
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController(); 
  String? selectedCategory;
  final List<String> categories = [
    "Món chiên", "Món xào", "Món hấp", "Món kho", "Món chay", "Món canh",
    "Món nước", "Món chè", "Món kem", "Salad", "Thức uống", "Gỏi/nộm"
  ];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<TextEditingController> ingredientControllers = [TextEditingController()];
  List<TextEditingController> stepControllers = [TextEditingController()];
  List<List<File>> stepImages = [[]]; 

  Future<void> _pickImage(ImageSource source, {int? stepIndex}) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (!mounted || image == null) return;
    setState(() {
      if (stepIndex == null) {
        _mainImages.add(File(image.path));
      } else {
        stepImages[stepIndex].add(File(image.path));
      }
    });
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showImagePicker(BuildContext context, {int? stepIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            _buildBottomSheetOption(Icons.image_outlined, "Thêm ảnh", () => _pickImage(ImageSource.gallery, stepIndex: stepIndex)),
            _buildBottomSheetOption(Icons.camera_alt_outlined, "Chụp ảnh", () => _pickImage(ImageSource.camera, stepIndex: stepIndex)),
            _buildBottomSheetOption(Icons.play_circle_outline, "Thêm video", () {}),
            _buildBottomSheetOption(Icons.videocam_outlined, "Quay video", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showActionMenu(BuildContext context, int index, bool isIngredient, Offset tapPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(tapPosition & const Size(40, 40), Offset.zero & overlay.size),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () {
            setState(() {
              if (isIngredient) {
                if (ingredientControllers.length > 1) ingredientControllers.removeAt(index);
              } else {
                if (stepControllers.length > 1) {
                  stepControllers.removeAt(index);
                  stepImages.removeAt(index);
                }
              }
            });
          },
          child: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text("Xóa", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }
  void _removeDropdown() { _overlayEntry?.remove(); _overlayEntry = null; }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 145,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4, borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ListView(
                padding: EdgeInsets.zero, shrinkWrap: true,
                children: categories.map((cat) => ListTile(
                  title: Text(cat),
                  onTap: () { setState(() => selectedCategory = cat); _removeDropdown(); },
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeDropdown();
    _nameController.dispose();
    _servingsController.dispose();
    for (var c in ingredientControllers) { c.dispose(); }
    for (var c in stepControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double stepImageSize = (MediaQuery.of(context).size.width - 80) / 2;
    return GestureDetector(
      onTap: () { FocusScope.of(context).unfocus(); _removeDropdown(); },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainImageSection(),
              const SizedBox(height: 20),
              _buildTextField(_nameController, "Tên món"),
              const SizedBox(height: 12),
              _buildCategoryRow(),
              const SizedBox(height: 12),
              _buildRowItem(label: "Khẩu phần", child: _buildTextField(_servingsController, "200 gr bột")),
              const SizedBox(height: 24),
              _buildIngredientSection(),
              const SizedBox(height: 24),
              _buildStepSection(stepImageSize),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white, elevation: 0,
      leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.pop(context)),
      actions: [
        TextButton(onPressed: () {}, child: const Text("Lưu", style: TextStyle(color: Colors.grey, fontSize: 16))),
        _buildCreateButton(),
        const Icon(Icons.more_vert, color: Colors.black),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("Tạo", style: TextStyle(color: Colors.black54)),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return _buildRowItem(
      label: "Thể loại",
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () => _overlayEntry == null ? _showDropdown() : _removeDropdown(),
          child: Container(
            height: 50, padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedCategory ?? "Chọn thể loại", style: TextStyle(color: selectedCategory == null ? Colors.black54 : Colors.black)),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Nguyên liệu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredientControllers.length,
          onReorder: (old, n) => setState(() {
            var newIdx = n > old ? n - 1 : n;
            ingredientControllers.insert(newIdx, ingredientControllers.removeAt(old));
          }),
          itemBuilder: (context, index) => _buildEditableRow(index, true, 0),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => ingredientControllers.add(TextEditingController())), 
            icon: const Icon(Icons.add, color: Colors.black), 
            label: const Text("Nguyên liệu", style: TextStyle(color: Colors.black))
          )
        ),
      ],
    );
  }

  Widget _buildStepSection(double imgSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Các bước chế biến", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stepControllers.length,
          onReorder: (old, n) => setState(() {
            var newIdx = n > old ? n - 1 : n;
            stepControllers.insert(newIdx, stepControllers.removeAt(old));
            stepImages.insert(newIdx, stepImages.removeAt(old));
          }),
          itemBuilder: (context, index) => _buildEditableRow(index, false, imgSize),
        ),
        Center(
          child: GestureDetector(
            onTap: () => setState(() { 
              stepControllers.add(TextEditingController()); 
              stepImages.add([]); 
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "+ Thêm bước", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(int index, bool isIngredient, double imgSize) {
    return Container(
      key: ValueKey(isIngredient ? "ing_$index" : "step_$index"),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (!isIngredient) CircleAvatar(radius: 11, backgroundColor: Colors.black, child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 11))),
              ReorderableDragStartListener(index: index, child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.menu, color: Colors.grey))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: isIngredient ? ingredientControllers[index] : stepControllers[index],
                  maxLines: isIngredient ? 1 : null,
                  decoration: InputDecoration(
                    hintText: isIngredient ? "200 gr bột" : "Mô tả bước...",
                    filled: true, fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: GestureDetector(
                      onTapDown: (d) => _showActionMenu(context, index, isIngredient, d.globalPosition),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
                if (!isIngredient) _buildStepImageGrid(index, imgSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepImageGrid(int index, double size) {
    return Padding(
      padding: const EdgeInsets.only(top: 12), 
      child: Align(
        alignment: Alignment.centerLeft, 
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.start, 
          children: [
            GestureDetector(
              onTap: () => _showImagePicker(context, stepIndex: index),
              child: Container(
                width: size,
                height: size * 0.75,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
              ),
            ),

            ...stepImages[index].asMap().entries.map((e) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    e.value, 
                    width: size, 
                    height: size * 0.75, 
                    fit: BoxFit.cover
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => setState(() => stepImages[index].removeAt(e.key)),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                )
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageSection() {
    return Container(
      width: double.infinity, height: 200,
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
      child: _mainImages.isEmpty
          ? InkWell(onTap: () => _showImagePicker(context), child: const Center(child: Text("Đăng hình đại diện", style: TextStyle(color: Colors.grey))))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mainImages.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_mainImages[index], width: 160, fit: BoxFit.cover)),
                  Positioned(top: 5, right: 5, child: GestureDetector(onTap: () => setState(() => _mainImages.removeAt(index)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.black, child: Icon(Icons.close, size: 12, color: Colors.white)))),
                ]),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint, filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _buildRowItem({required String label, required Widget child}) {
    return Row(children: [SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))), Expanded(child: child)]);
  }
}