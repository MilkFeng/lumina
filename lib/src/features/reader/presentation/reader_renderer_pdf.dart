import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/application/pdf_password_manager.dart';
import 'package:lumina/src/features/library/data/repositories/shelf_book_repository_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

/// Controller for PDF reader widget
class PdfReaderRendererController {
  _PdfReaderRendererState? _rendererState;

  /// Function to call when page changes
  Function(int page, int total)? onPageChanged;

  /// Function to call when renderer is ready
  VoidCallback? onRendererReady;

  /// Function to call when an error occurs
  Function(String error)? onError;

  /// Callback to trigger page transition animation
  /// Parameters: (targetPage, isForward)
  Future<void> Function(int targetPage, bool isForward)? onAnimateTransition;

  /// PDF view controller for direct page navigation
  dynamic pdfViewController;

  void _attachState(_PdfReaderRendererState? state) {
    _rendererState = state;
  }

  bool get isAttached => _rendererState != null;

  /// Get current page number
  Future<int> getCurrentPage() async {
    if (pdfViewController != null) {
      try {
        return await pdfViewController.getCurrentPage() ?? 0;
      } catch (e) {
        debugPrint('Error getting current page: $e');
        return 0;
      }
    }
    return 0;
  }

  /// Navigate to a specific page with animation (0-based)
  Future<void> goToPage(int targetPage) async {
    if (pdfViewController == null) return;

    try {
      final currentPage = await getCurrentPage();
      if (currentPage == targetPage) return;

      final isForward = targetPage > currentPage;

      // Trigger animation if callback is set
      if (onAnimateTransition != null) {
        await onAnimateTransition!(targetPage, isForward);
      } else {
        // Fallback: direct navigation without animation
        await pdfViewController.setPage(targetPage);
      }
    } catch (e) {
      debugPrint('Error navigating to page $targetPage: $e');
    }
  }

  /// Navigate to next page with animation
  Future<void> nextPage() async {
    final currentPage = await getCurrentPage();
    await goToPage(currentPage + 1);
  }

  /// Navigate to previous page with animation
  Future<void> previousPage() async {
    final currentPage = await getCurrentPage();
    await goToPage(currentPage - 1);
  }
}

/// PDF reader widget using flutter_pdfview
/// Supports password-protected PDFs, page navigation, and zoom
class PdfReaderRenderer extends ConsumerStatefulWidget {
  final ShelfBook book;
  final PdfReaderRendererController controller;
  final int initialPage;
  final Color backgroundColor;
  final bool showControls;
  final VoidCallback onToggleControls;

  const PdfReaderRenderer({
    super.key,
    required this.book,
    required this.controller,
    required this.showControls,
    required this.onToggleControls,
    this.initialPage = 0,
    this.backgroundColor = Colors.white,
  });

  @override
  ConsumerState<PdfReaderRenderer> createState() => _PdfReaderRendererState();
}

class _PdfReaderRendererState extends ConsumerState<PdfReaderRenderer>
    with SingleTickerProviderStateMixin {
  final PdfPasswordManager _passwordManager = PdfPasswordManager();

  // Stable key to prevent PDFView rebuild
  final GlobalKey _pdfViewKey = GlobalKey();

  // Loading state
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // PDF state
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isPasswordRequired = false;
  bool _passwordVerified = false;
  String? _retrievedPassword;
  String? _decryptedPdfPath;

  // Password dialog state
  String _passwordInput = '';
  bool _isAuthenticating = false;
  String? _authError;

  // Page transition animation state
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    
    widget.controller._attachState(this);
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Set animation callback in controller
    widget.controller.onAnimateTransition = _performPageTransition;
    
    _checkPasswordRequirement();
  }

  @override
  void dispose() {
    widget.controller._attachState(null);
    _fadeController.dispose();
    _cleanupDecryptedFile();
    super.dispose();
  }

  /// Clean up temporary decrypted PDF file
  void _cleanupDecryptedFile() {
    if (_decryptedPdfPath != null) {
      try {
        final file = File(_decryptedPdfPath!);
        if (file.existsSync()) {
          file.deleteSync();
          debugPrint('Cleaned up decrypted PDF: $_decryptedPdfPath');
        }
      } catch (e) {
        debugPrint('Error cleaning up decrypted PDF: $e');
      }
    }
  }

  /// Perform page transition with fade animation
  Future<void> _performPageTransition(int targetPage, bool isForward) async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    // Fade out
    await _fadeController.forward();

    // Navigate to target page
    if (widget.controller.pdfViewController != null) {
      await widget.controller.pdfViewController.setPage(targetPage);
    }

    // Small delay for page rendering
    await Future.delayed(const Duration(milliseconds: 100));

    // Fade in
    await _fadeController.reverse();

    setState(() {
      _isAnimating = false;
    });
  }

  /// Check if this PDF requires a password
  Future<void> _checkPasswordRequirement() async {
    if (!widget.book.isPasswordProtected) {
      setState(() {
        _passwordVerified = true;
      });
      debugPrint('PdfReaderRenderer: No password required, verified=true');
      return;
    }

    // Check if we have a stored password
    final hasPassword = await _passwordManager.hasPassword(
      widget.book.fileHash,
    );
    debugPrint('PdfReaderRenderer: hasPassword=$hasPassword');
    if (hasPassword) {
      // Retrieve the actual password from secure storage
      _retrievedPassword = await _passwordManager.getPassword(
        widget.book.fileHash,
      );
      debugPrint('PdfReaderRenderer: Password retrieved successfully');
      setState(() {
        _passwordVerified = true;
      });
    } else {
      setState(() {
        _isPasswordRequired = true;
        _isLoading = false;
      });
    }
  }

  /// Get the full file path for the PDF
  Future<String> _getFilePath() async {
    final docPath = AppStorage.documentsPath;
    final relativePath = widget.book.filePath ?? '';

    // Construct the absolute path
    final fullPath = '$docPath$relativePath';

    return fullPath;
  }

  /// Get PDF path, decrypting if necessary
  Future<String> _getPdfPath() async {
    final originalPath = await _getFilePath();

    // If not password-protected or no password retrieved, return original
    if (_retrievedPassword == null || _retrievedPassword!.isEmpty) {
      return originalPath;
    }

    // Check if we already have a decrypted version
    if (_decryptedPdfPath != null && File(_decryptedPdfPath!).existsSync()) {
      return _decryptedPdfPath!;
    }

    try {
      // Read original PDF file
      final originalFile = File(originalPath);
      final bytes = await originalFile.readAsBytes();

      // Decrypt using syncfusion_flutter_pdf
      debugPrint('Decrypting PDF with password...');
      final pdfDocument = PdfDocument(
        inputBytes: bytes,
        password: _retrievedPassword!,
      );

      // Remove security/encryption before saving
      pdfDocument.security.userPassword = '';
      pdfDocument.security.ownerPassword = '';
      debugPrint('Removed PDF security/encryption');

      // Save decrypted version to temp directory
      final tempDir = await getTemporaryDirectory();
      _decryptedPdfPath = '${tempDir.path}/decrypted_${widget.book.fileHash}.pdf';
      
      final decryptedBytes = await pdfDocument.save();
      await File(_decryptedPdfPath!).writeAsBytes(decryptedBytes);
      
      pdfDocument.dispose();
      
      debugPrint('PDF decrypted successfully: $_decryptedPdfPath');
      return _decryptedPdfPath!;
    } catch (e) {
      debugPrint('Error decrypting PDF: $e - wrong password, deleting and prompting');
      // Password is wrong - delete it and prompt user again
      await _passwordManager.deletePassword(widget.book.fileHash);
      
      // Update state to show password dialog
      if (mounted) {
        setState(() {
          _retrievedPassword = null;
          _passwordVerified = false;
          _isPasswordRequired = true;
          _isLoading = false;
          _hasError = false; // Clear error state
        });
      }
      
      // Return original path (will fail, but state is already updated to show password dialog)
      return originalPath;
    }
  }

  /// Handle tap gesture
  void _handleTap(TapUpDetails details) {
    debugPrint('handleTap triggered at position: ${details.globalPosition}');
    if (widget.showControls) {
      // Controls shown → hide them
      widget.onToggleControls();
      return;
    }
    // Controls hidden → check tap zones
    _handleTapZone(details.globalPosition.dx, details.globalPosition.dy);
  }

  void _handleTapZone(double x, double y) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 0) return;

    final ratio = x / width;
    if (ratio < 0.3) {
      // Left zone → previous page
      widget.controller.previousPage();
    } else if (ratio > 0.7) {
      // Right zone → next page
      widget.controller.nextPage();
    } else {
      // Middle zone → toggle controls
      widget.onToggleControls();
    }
  }

  /// Handle horizontal drag - use controller's unified navigation
  Future<void> _handleHorizontalDragEnd(DragEndDetails details) async {
    if (widget.showControls) return; // Disabled when controls shown
    if (_isAnimating) return; // Prevent overlapping animations

    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return; // Require minimum velocity

    if (velocity < -200) {
      // Swiped left → next page
      await widget.controller.nextPage();
    } else if (velocity > 200) {
      // Swiped right → previous page
      await widget.controller.previousPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isPasswordRequired && !_passwordVerified) {
      return _buildPasswordDialog();
    }

    // Show loading only if password-protected and password not yet verified
    // Once password is verified, proceed to build PDF viewer
    if (_isLoading && widget.book.isPasswordProtected && !_passwordVerified) {
      return _buildLoadingWidget();
    }

    // Use Stack with transparent overlay to intercept gestures
    // PDFView consumes touch events, so we need an overlay to capture taps
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: PDF viewer (bottom)
          _buildPdfViewer(),
          
          // Layer 2: Transparent gesture overlay (top)
          // This intercepts taps before PDFView can consume them
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: _handleTap,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(color: _getTextColorForBackground()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading PDF',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordDialog() {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Password Required',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This PDF is password-protected.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter password',
                      errorText: _authError,
                      filled: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _passwordInput = value;
                        _authError = null;
                      });
                    },
                    onSubmitted: (_) => _submitPassword(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      _isAuthenticating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              onPressed: _passwordInput.isNotEmpty
                                  ? _submitPassword
                                  : null,
                              child: const Text('Open'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        color: widget.backgroundColor,
        child: FutureBuilder<String>(
        future: _getPdfPath(), // Use _getPdfPath instead of _getFilePath
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingWidget();
          }

          final filePath = snapshot.data!;

          final file = File(filePath);
          if (!file.existsSync()) {
            try {
              final parentDir = file.parent;
              if (parentDir.existsSync()) {
                parentDir.listSync().forEach((f) {});
              }
            } catch (e) {
              debugPrint('PDF Viewer: Error listing directory: $e');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _hasError = true;
                _errorMessage = 'File not found: $filePath';
              });
            });
            return _buildLoadingWidget();
          }

          return PDFView(
            key: _pdfViewKey, // Stable key prevents unnecessary rebuilds
            filePath: filePath,
            password: null, // Password already handled via decryption
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: false,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.BOTH,
            onRender: (pages) {
              if (pages != null) {
                setState(() {
                  _totalPages = pages;
                  _isLoading = false;
                });
              }
              widget.controller.onRendererReady?.call();
            },
            onError: (error) {
              setState(() {
                _hasError = true;
                _errorMessage = error.toString();
                _isLoading = false;
              });
              widget.controller.onError?.call(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Error on page $page: $error';
              });
            },
            onViewCreated: (controller) {
              // Store the controller for page navigation
              widget.controller.pdfViewController = controller;
            },
            onPageChanged: (page, total) {
              if (page != null && total != null) {
                final int safePage = page.clamp(0, total - 1);
                setState(() {
                  _currentPage = safePage;
                  _totalPages = total;
                });
                widget.controller.onPageChanged?.call(safePage, total);
                // Note: Progress saving is handled by reader_screen's onPageChanged callback
                // No need to save here - this was causing duplicate/conflicting saves
              }
            },
          );
        },
      ),
    ));
  }

  Color _getTextColorForBackground() {
    if (widget.backgroundColor.computeLuminance() > 0.5) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  Future<void> _submitPassword() async {
    if (_passwordInput.isEmpty) return;

    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      // Verify password by actually decrypting the PDF
      final file = File(await _getFilePath());
      final bytes = await file.readAsBytes();

      // Try to decrypt with the password - this will throw if password is wrong
      final pdfDocument = PdfDocument(
        inputBytes: bytes,
        password: _passwordInput,
      );
      
      // Password is correct - dispose the test document
      pdfDocument.dispose();
      debugPrint('Password verified successfully');

      // Save the verified password
      await _passwordManager.savePassword(widget.book.fileHash, _passwordInput);

      setState(() {
        _retrievedPassword = _passwordInput; // Store for decryption
        _passwordVerified = true;
        _isPasswordRequired = false;
        _isAuthenticating = false;
        _passwordInput = '';
      });
    } catch (e) {
      debugPrint('Password verification failed: $e');
      setState(() {
        _authError = 'Incorrect password';
        _isAuthenticating = false;
        // Keep password dialog open for retry
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isLoading = true;
    });

    // Re-check password requirement
    await _checkPasswordRequirement();

    if (!_isPasswordRequired || _passwordVerified) {
      setState(() {
        _isLoading = true;
      });
    }
  }

  /// Public method to navigate to a specific page
  void goToPage(int page) {
    // This would require access to the PDFView controller
    // For now, we'll rely on the widget rebuilding with new initialPage
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  /// Get current page number (0-based)
  int get currentPage => _currentPage;

  /// Get total page count
  int get totalPages => _totalPages;
}
