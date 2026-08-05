import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/firebase_service.dart';
import 'save_recipe.dart';
import 'status_recipe.dart';
import '../../data/models/recipe.dart';

class CreateRecipeScreen extends StatefulWidget {
  final String? draftId;
  const CreateRecipeScreen({
    super.key,
    this.draftId,
  });
  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _RecipeMedia {
  final File? file;
  final String? url;
  final String type;
  const _RecipeMedia({
    this.file,
    this.url,
    required this.type,
  });
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _svc = FirebaseService();
  String? _draftId;
  final List<_RecipeMedia> _mainMedia = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  String? selectedCategory;
  final List<String> categories = [
    'Món chiên',
    'Món xào',
    'Món hấp',
    'Món kho',
    'Món chay',
    'Món canh',
    'Món nước',
    'Món chè',
    'Món kem',
    'Salad',
    'Thức uống',
    'Gỏi/nộm',
  ];
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final List<TextEditingController> ingredientControllers = [TextEditingController()];
  final List<TextEditingController> stepTitleControllers = [TextEditingController()];
  final List<TextEditingController> stepDescriptionControllers = [TextEditingController()];
  final List<List<_RecipeMedia>> stepMedia = [[]];

  Future<void> _pickMedia({
    required ImageSource source,
    required bool isVideo,
    int? stepIndex,
  }) async {
    final XFile? picked = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(source: source);
    if (!mounted || picked == null) return;
    final media = _RecipeMedia(
      file: File(picked.path),
      url: null,
      type: isVideo ? 'video' : 'image',
    );
    setState(() {
      if (stepIndex == null) {
        _mainMedia.add(media);
      } else {
        if (stepIndex >= stepMedia.length) {
          stepMedia.add([]);
        }
        if (stepIndex < stepMedia.length) {
          stepMedia[stepIndex].add(media);
        }
      }
    });
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showImagePicker(BuildContext context, {int? stepIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            _buildBottomSheetOption(
              Icons.image_outlined,
              'Thêm ảnh',
              () => _pickMedia(
                source: ImageSource.gallery,
                isVideo: false,
                stepIndex: stepIndex,
              ),
            ),
            _buildBottomSheetOption(
              Icons.camera_alt_outlined,
              'Chụp ảnh',
              () => _pickMedia(
                source: ImageSource.camera,
                isVideo: false,
                stepIndex: stepIndex,
              ),
            ),
            _buildBottomSheetOption(
              Icons.play_circle_outline,
              'Thêm video',
              () => _pickMedia(
                source: ImageSource.gallery,
                isVideo: true,
                stepIndex: stepIndex,
              ),
            ),
            _buildBottomSheetOption(
              Icons.videocam_outlined,
              'Quay video',
              () => _pickMedia(
                source: ImageSource.camera,
                isVideo: true,
                stepIndex: stepIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showActionMenu(
    BuildContext context,
    int index,
    bool isIngredient,
    Offset tapPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          onTap: () {
            setState(() {
              if (isIngredient) {
                if (ingredientControllers.length > 1) {
                  ingredientControllers.removeAt(index);
                }
              } else {
                if (stepTitleControllers.length > 1) {
                  stepTitleControllers.removeAt(index);
                  stepDescriptionControllers.removeAt(index);
                  stepMedia.removeAt(index);
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

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 145,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: categories
                    .map(
                      (cat) => ListTile(
                        title: Text(cat),
                        onTap: () {
                          setState(() => selectedCategory = cat);
                          _removeDropdown();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _draftId = widget.draftId;
    if (_draftId != null) {
      _loadDraft();
    }
  }

  @override
  void dispose() {
    _removeDropdown();
    _nameController.dispose();
    _servingsController.dispose();
    for (var c in ingredientControllers) {
      c.dispose();
    }
    for (var c in stepTitleControllers) {
      c.dispose();
    }
    for (var c in stepDescriptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDraft() async {
    if (_draftId == null) return;
    final doc = await _svc.getDraft(_draftId!);
    if (doc == null || !doc.exists) {
      _draftId = null;
      return;
    }
    final data = doc.data()!;
    _nameController.text = data["title"] ?? "";
    _servingsController.text = data["servings"] ?? "";
    selectedCategory = data["category"];
    _mainMedia.clear();
    if ((data["imageUrl"] ?? "").toString().isNotEmpty) {
      _mainMedia.add(
        _RecipeMedia(
          url: data["imageUrl"],
          type: data["mainMediaType"] ?? "image",
        ),
      );
    }
    for (final c in ingredientControllers) {
      c.dispose();
    }
    ingredientControllers.clear();

    final ingredients = List<String>.from(
      data["ingredients"] ?? [],
    );
    if (ingredients.isEmpty) {
      ingredientControllers.add(TextEditingController());
    } else {
      for (final ingredient in ingredients) {
        ingredientControllers.add(
          TextEditingController(text: ingredient),
        );
      }
    }
    for (final c in stepTitleControllers) {
      c.dispose();
    }
    for (final c in stepDescriptionControllers) {
      c.dispose();
    }
    stepTitleControllers.clear();
    stepDescriptionControllers.clear();
    stepMedia.clear();
    final rawSteps = data["steps"] ?? [];
    final medias = List<Map<String, dynamic>>.from(
      data["stepMedia"] ?? [],
    );
    if (rawSteps is List && rawSteps.isNotEmpty) {
      for (int i = 0; i < rawSteps.length; i++) {
        final stepData = rawSteps[i];
        String title = '';
        String description = '';
        if (stepData is String) {
          description = stepData;
        } else if (stepData is Map<String, dynamic>) {
          title = stepData["title"]?.toString() ?? '';
          description = stepData["description"]?.toString() ?? '';
        }
        stepTitleControllers.add(TextEditingController(text: title));
        stepDescriptionControllers.add(TextEditingController(text: description));
        final List<_RecipeMedia> mediaList = [];
        final mediaData = medias.where(
          (e) => e["stepIndex"] == i,
        );
        for (final item in mediaData) {
          final media = List<Map<String, dynamic>>.from(
            item["media"] ?? [],
          );
          for (final m in media) {
            mediaList.add(
              _RecipeMedia(
                url: m["url"],
                type: m["type"] ?? "image",
              ),
            );
          }
        }
        stepMedia.add(mediaList);
      }
    }
    if (stepTitleControllers.isEmpty) {
      stepTitleControllers.add(TextEditingController());
      stepDescriptionControllers.add(TextEditingController());
      stepMedia.add([]);
    }
    setState(() {});
  }
  Future<void> _saveDraft() async {
    final title = _nameController.text.trim();
    final servings = _servingsController.text.trim();
    final ingredientTexts = ingredientControllers
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final recipeSteps = <RecipeStep>[];
      for (int i = 0; i < stepTitleControllers.length; i++) {
        final title = stepTitleControllers[i].text.trim();
        final description = stepDescriptionControllers[i].text.trim();
        if (title.isEmpty && description.isEmpty) continue;
        recipeSteps.add(
          RecipeStep(
            stepNumber: recipeSteps.length + 1,
            title: title,
            description: description,
            images: const [],
          ),
        );
      }
    final draftId = await _svc.saveDraft(
      draftId: _draftId,
      title: title.isEmpty ? "Chưa đặt tên" : title,
      category: selectedCategory ?? "",
      servings: servings.isEmpty ? "1 phần" : servings,
      ingredients: ingredientTexts,
      steps: recipeSteps,
      mainMediaFiles: _mainMedia
          .where((m) => m.file != null)
          .map((m) => m.file!)
          .toList(),
      mainMediaTypes: _mainMedia.map((m) => m.type).toList(),
      stepMediaFiles: stepMedia
          .map(
            (list) => list
                .where((m) => m.file != null)
                .map((m) => m.file!)
                .toList(),
          )
          .toList(),
      stepMediaTypes: stepMedia
          .map((list) => list.map((m) => m.type).toList())
          .toList(),
    );
    if (!mounted) return;
    if (draftId != null) {
      _draftId = draftId;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã lưu bản nháp"),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SaveRecipeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _svc.lastError ?? "Không thể lưu bản nháp",
          ),
        ),
      );
    }
  }

  Future<void> _submitRecipe() async {
    final title = _nameController.text.trim();
    final servings = _servingsController.text.trim();
    if (title.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên món và chọn thể loại')),
      );
      return;
    }
    final ingredientTexts = ingredientControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final recipeSteps = <RecipeStep>[];
      for (int i = 0; i < stepTitleControllers.length; i++) {
        final title = stepTitleControllers[i].text.trim();
        final description = stepDescriptionControllers[i].text.trim();
        if (title.isEmpty && description.isEmpty) continue;
        recipeSteps.add(
          RecipeStep(
            stepNumber: recipeSteps.length + 1,
            title: title,
            description: description,
            images: const [],
          ),
        );
      }
    final isAdminFlow = _svc.isAdminUser;
    final recipeId = isAdminFlow
        ? await _svc.createRecipe(
            title: title,
            category: selectedCategory!,
            servings: servings.isEmpty ? '1 phần' : servings,
            ingredients: ingredientTexts,
            steps: recipeSteps,
            isAdmin: true,
            mainMediaFiles: _mainMedia
                .where((m) => m.file != null)
                .map((m) => m.file!)
                .toList(),
            mainMediaTypes: _mainMedia.map((m) => m.type).toList(),
            stepMediaFiles: stepMedia
                .map(
                  (list) => list
                      .where((m) => m.file != null)
                      .map((m) => m.file!)
                      .toList(),
                )
                .toList(),
            stepMediaTypes: stepMedia
                .map((list) => list.map((m) => m.type).toList())
                .toList(),
          )
        : await _svc.createReviewRequest(
            title: title,
            category: selectedCategory!,
            servings: servings.isEmpty ? '1 phần' : servings,
            ingredients: ingredientTexts,
            steps: recipeSteps,
            mainMediaFiles: _mainMedia
                .where((m) => m.file != null)
                .map((m) => m.file!)
                .toList(),
            mainMediaTypes: _mainMedia.map((m) => m.type).toList(),
            stepMediaFiles: stepMedia
                .map(
                  (list) => list
                      .where((m) => m.file != null)
                      .map((m) => m.file!)
                      .toList(),
                )
                .toList(),
            stepMediaTypes: stepMedia
                .map((list) => list.map((m) => m.type).toList())
                .toList(),
          );
    if (!mounted) return;
    if (recipeId != null) {
      if (_draftId != null) {
        await _svc.deleteDraft(_draftId!);
        if (!mounted) return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng món thành công')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_svc.lastError ?? 'Đăng món thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double stepImageSize = (MediaQuery.of(context).size.width - 80) / 2;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _removeDropdown();
      },
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
              _buildRowItem(
                label: "Khẩu phần",
                child: _buildTextField(_servingsController, "Cho 4 người"),
              ),
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
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _saveDraft,
          child: const Text(
            "Lưu",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildCreateButton(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'draft') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SaveRecipeScreen(),
                ),
              );
            }
            if (value == 'status' && !_svc.isAdminUser) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatusRecipeScreen(),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'draft',
              child: Text("Bản nháp"),
            ),
            if (!_svc.isAdminUser)
              const PopupMenuItem(
                value: 'status',
                child: Text("Đơn đã tạo"),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: ElevatedButton(
        onPressed: _submitRecipe,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          _svc.isAdminUser ? 'Đăng' : 'Tạo',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return _buildRowItem(
      label: "Thể loại",
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          onTap: () =>
              _overlayEntry == null ? _showDropdown() : _removeDropdown(),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory ?? "Chọn thể loại",
                  style: TextStyle(
                    color: selectedCategory == null
                        ? Colors.black54
                        : Colors.black,
                  ),
                ),
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
        const Text(
          "Nguyên liệu",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ingredientControllers.length,
          onReorder: (old, n) => setState(() {
            var newIdx = n > old ? n - 1 : n;
            ingredientControllers.insert(
              newIdx,
              ingredientControllers.removeAt(old),
            );
          }),
          itemBuilder: (context, index) => _buildEditableRow(index, true, 0),
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(
              () => ingredientControllers.add(TextEditingController()),
            ),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text(
              "Nguyên liệu",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepSection(double imgSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Các bước chế biến",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stepTitleControllers.length,
          onReorder: (old, n) => setState(() {
            var newIdx = n > old ? n - 1 : n;
            stepTitleControllers.insert(newIdx, stepTitleControllers.removeAt(old));
            stepDescriptionControllers.insert(newIdx, stepDescriptionControllers.removeAt(old));
            stepMedia.insert(newIdx, stepMedia.removeAt(old));
          }),
          itemBuilder: (context, index) =>
              _buildEditableRow(index, false, imgSize),
        ),
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              stepTitleControllers.add(TextEditingController());
              stepDescriptionControllers.add(TextEditingController());
              stepMedia.add([]);
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "+ Thêm bước",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
              if (!isIngredient)
                CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Icon(Icons.menu, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: isIngredient
                      ? ingredientControllers[index]
                      : stepTitleControllers[index],
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: isIngredient ? "200 gr bột" : "Tiêu đề bước...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: GestureDetector(
                      onTapDown: (d) => _showActionMenu(
                        context,
                        index,
                        isIngredient,
                        d.globalPosition,
                      ),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ),
                if (!isIngredient) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: stepDescriptionControllers[index],
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Mô tả bước...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
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
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.grey,
                ),
              ),
            ),
            ...stepMedia[index].asMap().entries.map(
              (e) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: e.value.type == 'video'
                        ? Container(
                            width: size,
                            height: size * 0.75,
                            color: Colors.black12,
                            child: const Icon(
                              Icons.videocam,
                              size: 40,
                              color: Colors.orange,
                            ),
                          )
                        : e.value.file != null
                            ? Image.file(
                                e.value.file!,
                                width: size,
                                height: size * 0.75,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                e.value.url!,
                                width: size,
                                height: size * 0.75,
                                fit: BoxFit.cover,
                              ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => stepMedia[index].removeAt(e.key)),
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImageSection() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _mainMedia.isEmpty
          ? InkWell(
              onTap: () => _showImagePicker(context),
              child: const Center(
                child: Text(
                  "Đăng hình đại diện",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mainMedia.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _mainMedia[index].type == 'video'
                          ? Container(
                              width: 160,
                              height: 160,
                              color: Colors.black12,
                              child: const Icon(
                                Icons.videocam,
                                size: 50,
                                color: Colors.orange,
                              ),
                            )
                          : _mainMedia[index].file != null
                              ? Image.file(
                                  _mainMedia[index].file!,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _mainMedia[index].url!,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => setState(() => _mainMedia.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black,
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRowItem({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
