class ChecklistModel {
  final int checklistId;
  final String? checklistName;
  final String? description;
  final bool? forChildren;
  final bool? forElderly;
  final bool? forPwd;
  final List<dynamic>? items;

  ChecklistModel({
    required this.checklistId,
    this.checklistName,
    this.description,
    this.forChildren,
    this.forElderly,
    this.forPwd,
    this.items,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> items = [];
    if (json['items'] != null) {
      items = json['items'] is List ? json['items'] : [];
    }

    return ChecklistModel(
      checklistId: json['checklist_id'] ?? 0,
      checklistName: json['checklist_name'],
      description: json['description'],
      forChildren: json['for_children'] == 1,
      forElderly: json['for_elderly'] == 1,
      forPwd: json['for_pwd'] == 1,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'checklist_id': checklistId,
    'checklist_name': checklistName,
    'description': description,
    'for_children': forChildren == true ? 1 : 0,
    'for_elderly': forElderly == true ? 1 : 0,
    'for_pwd': forPwd == true ? 1 : 0,
    'items': items,
  };
}

class ChecklistItemModel {
  final int itemId;
  final int? checklistId;
  final String? itemDescription;

  ChecklistItemModel({
    required this.itemId,
    this.checklistId,
    this.itemDescription,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      itemId: json['item_id'] ?? 0,
      checklistId: json['checklist_id'],
      itemDescription: json['item_description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'checklist_id': checklistId,
    'item_description': itemDescription,
  };
}
