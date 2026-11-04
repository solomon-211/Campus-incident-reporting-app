import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/widgets/category_tile.dart';
import '../../core/widgets/hero_header.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/incident.dart';
import '../auth/cubit/auth_cubit.dart';
import 'cubit/report_form_cubit.dart';

class ReportFormScreen extends StatelessWidget {
  const ReportFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportFormCubit, ReportFormState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        switch (state.status) {
          case ReportFormStatus.success:
            context.showSnack('Report submitted. Thank you!');
            context.pushReplacement('/incident/${state.createdIncidentId}');
          case ReportFormStatus.failure:
            context.showSnack(
              state.errorMessage ?? 'Something went wrong',
              error: true,
            );
          default:
            break;
        }
      },
      child: const Scaffold(
        body: Column(
          children: [
            _FormHeader(),
            Expanded(child: SafeArea(top: false, child: _ReportForm())),
          ],
        ),
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return const HeroHeader(
      padding: EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: HeaderTitleBar(title: 'Report an Incident'),
    );
  }
}

class _ReportForm extends StatelessWidget {
  const _ReportForm();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportFormCubit>();
    return BlocBuilder<ReportFormCubit, ReportFormState>(
      builder: (context, state) {
        final show = state.showErrors;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _Label('Select a category'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                for (final c in IncidentCategory.values)
                  CategoryTile(
                    category: c,
                    selected: state.category == c,
                    onTap: state.isSubmitting
                        ? () {}
                        : () => cubit.setCategory(c),
                  ),
              ],
            ),
            if (show && state.categoryError != null)
              _ErrorText(state.categoryError!),
            const SizedBox(height: 20),
            const _Label('Title'),
            TextFormField(
              enabled: !state.isSubmitting,
              maxLength: AppConstants.titleMaxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: cubit.setTitle,
              decoration: InputDecoration(
                hintText: 'Briefly describe the issue...',
                errorText: show ? state.titleError : null,
              ),
            ),
            const SizedBox(height: 8),
            const _Label('Description'),
            TextFormField(
              enabled: !state.isSubmitting,
              minLines: 4,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: cubit.setDescription,
              decoration: InputDecoration(
                hintText:
                    'Provide more details about the issue...\n'
                    'e.g. what happened, when, impact, etc.',
                errorText: show ? state.descriptionError : null,
              ),
            ),
            const SizedBox(height: 20),
            const _Label('Location'),
            DropdownButtonFormField<String>(
              initialValue: state.location,
              isExpanded: true,
              hint: const Text('Select a location'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined),
                errorText: show ? state.locationError : null,
              ),
              items: [
                for (final l in AppConstants.locations)
                  DropdownMenuItem(value: l, child: Text(l)),
              ],
              onChanged: state.isSubmitting
                  ? null
                  : (v) => v == null ? null : cubit.setLocation(v),
            ),
            const SizedBox(height: 20),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _Label('Add a photo'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    ' (optional, up to ${AppConstants.maxPhotos})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            _PhotoPicker(state: state),
            if (show && state.photosError != null)
              _ErrorText(state.photosError!),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                value: state.isAnonymous,
                onChanged: state.isSubmitting ? null : cubit.setAnonymous,
                secondary: const Icon(Icons.visibility_off_outlined),
                title: const Text(
                  'Report anonymously',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Your name is hidden from others. Useful for safety concerns.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (state.isSubmitting && state.images.isNotEmpty) ...[
              LinearProgressIndicator(borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 6),
              Text(
                'Compressing and saving photos…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: 'Submit Report',
              loading: state.isSubmitting,
              onPressed: () {
                final user = context.read<AuthCubit>().currentUser;
                if (user != null) cubit.submit(user);
              },
            ),
          ],
        );
      },
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.state});

  final ReportFormState state;

  Future<void> _pick(BuildContext context) async {
    final cubit = context.read<ReportFormCubit>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final remaining = AppConstants.maxPhotos - cubit.state.images.length;
    List<XFile> files;
    try {
      if (source == ImageSource.gallery && remaining > 1) {
        files = await picker.pickMultiImage(limit: remaining);
      } else {
        final file = await picker.pickImage(source: source);
        files = file == null ? [] : [file];
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Could not open the camera or gallery.', error: true);
      }
      return;
    }
    if (files.isEmpty) return;

    final bytes = <Uint8List>[for (final f in files) await f.readAsBytes()];
    final dropped = cubit.addImages(bytes);
    if (dropped > 0 && context.mounted) {
      context.showSnack(
        'Only ${AppConstants.maxPhotos} photos are allowed; '
        '$dropped not added.',
        info: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportFormCubit>();
    if (state.images.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: state.isSubmitting ? null : () => _pick(context),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 6),
              Text(
                'Tap to add photos',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < state.images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      state.images[i],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!state.isSubmitting)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => cubit.removeImage(i),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (state.canAddPhotos && !state.isSubmitting)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pick(context),
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }
}
