import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components/components.dart';
import 'data/sample_documents.dart';
import '../../api/parsed_documents_repository.dart';

class AnalysisPanel extends StatefulWidget {
  const AnalysisPanel({super.key, this.document});

  final SampleDocument? document;

  @override
  State<AnalysisPanel> createState() => _AnalysisPanelState();
}

class _AnalysisPanelState extends State<AnalysisPanel> {
  Map<String, dynamic>? analysis;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // If this is a server document id like 'server-123', extract numeric id
      final String? idStr = widget.document?.id;
      if (idStr != null && idStr.startsWith('server-')) {
        final int id = int.parse(idStr.split('-').last);
        final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
        try {
          final data = await repo.fetchAnalysis(id);
          setState(() {
            analysis = data;
          });
        } catch (e) {
          // If analysis not ready yet (404), wait/poll for it
          final message = e.toString();
          final bool isPending = message.contains('404') || message.contains('Analysis not available');
          if (isPending) {
            final DateTime deadline = DateTime.now().add(const Duration(seconds: 30));
            Map<String, dynamic>? polled;
            while (DateTime.now().isBefore(deadline) && mounted) {
              await Future.delayed(const Duration(seconds: 2));
              try {
                final Map<String, dynamic> d = await repo.fetchAnalysis(id);
                polled = d;
                break;
              } catch (_) {
                // keep polling until timeout
              }
            }
            if (polled != null) {
              setState(() {
                analysis = polled;
              });
            } else {
              setState(() {
                error = 'Analysis not available';
              });
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Text(
              'Analysis & Insights',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Failed to load analysis', style: GoogleFonts.inter(color: const Color(0xFF991B1B))),
                            const SizedBox(height: 8),
                            Text(error!, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF991B1B))),
                            const SizedBox(height: 12),
                            OutlinedButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _buildAnalysisView(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    final Map<String, dynamic> a = analysis ?? {};
    final List<dynamic> tldr = (a['tldr_bullets'] ?? []) as List<dynamic>;
    final List<dynamic> clauses = (a['clauses'] ?? []) as List<dynamic>;
    final List<dynamic> flags = (a['risk_flags'] ?? []) as List<dynamic>;
    final List<dynamic> comp = (a['comparative_context'] ?? []) as List<dynamic>;
    final List<dynamic> qs = (a['suggested_questions'] ?? []) as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      children: [
        if (tldr.isNotEmpty) ...[
          TldrBullets(bullets: tldr.cast<String>()),
          const SizedBox(height: 12),
        ],

        const ListHeader(title: 'Clause Breakdown'),
        const SizedBox(height: 10),
        ...clauses.map((c) {
          final String title = (c['category'] ?? 'Clause').toString();
          final String snippet = (c['original_snippet'] ?? '').toString();
          final String explanation = (c['explanation'] ?? '').toString();
          final String risk = (c['risk'] ?? 'low').toString();
          final ClauseRisk r = risk == 'high' ? ClauseRisk.high : risk == 'medium' ? ClauseRisk.medium : ClauseRisk.low;
          final IconData icon = Icons.article_outlined;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClauseBreakdownCard(title: title, icon: icon, originalSnippet: snippet, explanation: explanation, risk: r),
          );
        }),

        const SizedBox(height: 12),
        const ListHeader(title: 'Risk Flags & Warnings'),
        const SizedBox(height: 10),
        RiskFlagsList(
          items: flags.map((f) => RiskFlagItem(text: (f['text'] ?? '').toString(), level: (f['level'] ?? 'low').toString(), why: (f['why'] ?? '').toString())).cast<RiskFlagItem>().toList(),
        ),

        const SizedBox(height: 12),
        const ListHeader(title: 'Comparative Context'),
        const SizedBox(height: 10),
        ...comp.map((cc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ComparativeContextCard(
                label: (cc['label'] ?? '').toString(),
                standard: (cc['standard'] ?? '').toString(),
                contract: (cc['contract'] ?? '').toString(),
                assessment: (cc['assessment'] ?? '').toString(),
              ),
            )),

        const SizedBox(height: 12),
        const ListHeader(title: 'Suggested Questions'),
        const SizedBox(height: 10),
        SuggestedQuestions(questions: qs.cast<String>()),

        const SizedBox(height: 14),
        const SimulationCta(),
      ],
    );
  }
}

