enum LearnUnitProgressState { locked, inProgress, completed }

class LearnUnitModel {
  final int unitNumber;
  final String title;
  final String imageUrl;
  final double progressPercent;
  final LearnUnitProgressState progressState;

  const LearnUnitModel({
    required this.unitNumber,
    required this.title,
    required this.imageUrl,
    required this.progressPercent,
    required this.progressState
  });

  static const List<LearnUnitModel> sampleUnits = [
    LearnUnitModel(
      unitNumber: 1,
      title: 'Companies',
      imageUrl:
          'https://static.vecteezy.com/system/resources/previews/046/438/559/non_2x/checklist-clipboard-3d-icon-free-png.png',
      progressPercent: 1,
      progressState: LearnUnitProgressState.completed
    ),
    LearnUnitModel(
      unitNumber: 2,
      title: 'Contacts',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/628100-notebook/dynamic/200/color.webp',
      progressPercent: 1,
      progressState: LearnUnitProgressState.completed
    ),
    LearnUnitModel(
      unitNumber: 3,
      title: 'Product and services',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/5f20be-computer/dynamic/200/color.webp',
      progressPercent: 0.78,
      progressState: LearnUnitProgressState.inProgress
    ),
    LearnUnitModel(
      unitNumber: 4,
      title: 'Visitors',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/49b6f4-target/dynamic/200/color.webp',
      progressPercent: 0.55,
      progressState: LearnUnitProgressState.inProgress
    ),
    LearnUnitModel(
      unitNumber: 5,
      title: 'Customer service',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/49654f-trophy/dynamic/200/color.webp',
      progressPercent: 0.2,
      progressState: LearnUnitProgressState.inProgress
    ),
    LearnUnitModel(
      unitNumber: 6,
      title: 'Employment',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/66b0f8-pencil/dynamic/200/color.webp',
      progressPercent: 0,
      progressState: LearnUnitProgressState.locked
    ),
    LearnUnitModel(
      unitNumber: 7,
      title: 'Customer service',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/176980-folder/dynamic/200/color.webp',
      progressPercent: 0,
      progressState: LearnUnitProgressState.locked
    ),
    LearnUnitModel(
      unitNumber: 8,
      title: 'Employment',
      imageUrl:
          'https://bvconuycpdvgzbvbkijl.supabase.co/storage/v1/object/public/sizes/8924a0-mail/dynamic/200/color.webp',
      progressPercent: 0,
      progressState: LearnUnitProgressState.locked
    )
  ];
}
