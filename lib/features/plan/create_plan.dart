import 'package:flutter/material.dart';
import 'calendar_plan_screen.dart';
import '../../core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/recipe.dart';
import 'recipe_picker_sheet.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({
    super.key,
    this.planId,
    this.initialPlan,
  });

  final String? planId;
  final Map<String, dynamic>? initialPlan;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  Recipe? selectedRecipe;
  DateTime selectedDate = DateTime.now();
  String meal = "Bữa sáng";
  int quantity = 1;
  final FirebaseService _firebase = FirebaseService();
  final List<String> meals = [
    "Bữa sáng",
    "Bữa nhẹ sáng",
    "Bữa trưa",
    "Bữa xế chiều",
    "Bữa tối",
    "Bữa khuya",
  ];
  void _showMealPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: meals.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = meals[index];
              return ListTile(
                title: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                trailing: meal == item
                    ? const Icon(
                        Icons.check,
                        color: Colors.orange,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    meal = item;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _pickRecipe() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (_) {
        return RecipePickerSheet(
          onSelected: (recipe) {
            setState(() {
              selectedRecipe = recipe;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F4F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Kế hoạch",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leadingWidth: 80,
        leading: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 12),
            alignment: Alignment.centerLeft,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            "Thoát",
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: Colors.red,
              fontSize: 17,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text(
              "Lưu",
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _dateCard(),
          const SizedBox(height: 18),
          _recipeCard(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // If initial plan data provided (editing), pre-fill fields
    final init = widget.initialPlan;
    if (init != null) {
      if (init['date'] is Timestamp) {
        final ts = init['date'] as Timestamp;
        selectedDate = ts.toDate();
      } else if (init['date'] is DateTime) {
        selectedDate = init['date'];
      }
      meal = (init['meal'] as String?) ?? meal;
      quantity = (init['quantity'] as int?) ?? quantity;
      final recipeId = init['recipeId'] as String?;
      if (recipeId != null && recipeId.isNotEmpty) {
        _firebase.getRecipeById(recipeId).then((r) {
          if (r != null) {
            setState(() {
              selectedRecipe = r;
            });
          }
        });
      }
    }
  }

  Future<void> _onSave() async {
    if (selectedRecipe == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn món')));
      return;
    }
    final id = await _firebase.savePlan(
      planId: widget.planId,
      recipeId: selectedRecipe!.id,
      date: selectedDate,
      meal: meal,
      quantity: quantity,
    );
    if (id != null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu thất bại')));
    }
  }

  Widget _dateCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ListTile(
            minVerticalPadding: 0,
            leading: const Icon(
              Icons.calendar_today_outlined,
            ),
            title: Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _pickDate,
          ),
          const Divider(height: 1),
          ListTile(
            minVerticalPadding: 0,
            leading: const Icon(
              Icons.access_time,
            ),
            title: Text(
              meal,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: _showMealPicker,
          ),
        ],
      ),
    );
  }

  Widget _recipeCard() {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: _pickRecipe,
              borderRadius: BorderRadius.circular(10),
              child: selectedRecipe == null
                  ? ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.restaurant),
                      title: const Text("Món"),
                      subtitle: const Text("chưa có"),
                      trailing: const Icon(Icons.chevron_right),
                    )
                  : Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(8),
                          child: Image.network(
                            selectedRecipe!.thumbnail,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedRecipe!.name,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                        ),
                      ],
                    ),
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Text(
                  "Số lượng",
                  style: TextStyle(fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickDate() async {
    final result =
        await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarPlanScreen(
          selectedDate: selectedDate,
        ),
      ),
    );
    if(result != null){
      setState(() {
        selectedDate = result;
      });
    }
  }
}