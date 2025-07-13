import 'package:flutter/material.dart';

class SkillsInput extends StatefulWidget {
  final List<String> initialSkills;
  final Function(List<String>) onSkillsChanged;
  final bool enabled;

  const SkillsInput({
    super.key,
    required this.initialSkills,
    required this.onSkillsChanged,
    this.enabled = true,
  });

  @override
  State<SkillsInput> createState() => _SkillsInputState();
}

class _SkillsInputState extends State<SkillsInput> {
  final _skillController = TextEditingController();
  late List<String> _skills;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkills);
  }

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill) && _skills.length < 10) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
      widget.onSkillsChanged(_skills);
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
    widget.onSkillsChanged(_skills);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Skills input field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _skillController,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: 'E.g. Painting, Drawing, etc',
                  hintStyle: TextStyle(
                    color: widget.enabled ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  fillColor: widget.enabled ? null : Colors.grey.shade100,
                  filled: !widget.enabled,
                ),
                onFieldSubmitted: (_) => _addSkill(),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length < 2) {
                      return 'Skill must be at least 2 characters';
                    }
                    if (_skills.contains(value.trim())) {
                      return 'Skill already added';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.enabled && _skills.length < 10 ? _addSkill : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Add'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Skills limit indicator
        Text(
          '${_skills.length}/10 skills',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 16),

        // Current skills display
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) => _buildSkillChip(skill)).toList(),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No skills added yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.enabled 
            ? const Color(0xFF6C5CE7).withValues(alpha: 0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.enabled 
              ? const Color(0xFF6C5CE7).withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: TextStyle(
              color: widget.enabled 
                  ? const Color(0xFF6C5CE7)
                  : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.enabled) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeSkill(skill),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}