import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/http.dart';
import '../../../core/services/toast_service.dart';
import 'workorder_api_service.dart';
import '../models/workorder.dart';

// Approval workflow service provider
final approvalWorkflowServiceProvider = Provider<ApprovalWorkflowService>((ref) {
  return ApprovalWorkflowService(
    ref.read(workOrderApiServiceProvider),
    ref.read(toastServiceProvider),
  );
});

class ApprovalWorkflowService {
  final WorkOrderApiService _workOrderApi;
  final ToastService _toastService;

  ApprovalWorkflowService(this._workOrderApi, this._toastService);

  /// Request approval from engineer for a work order
  Future<WorkOrder> requestEngineerApproval(int workOrderId) async {
    try {
      final workOrder = await _workOrderApi.requestApproval(workOrderId);
      
      _toastService.showSuccess(
        'Approval request sent to engineer for Work Order #${workOrder.id}',
      );
      
      return workOrder;
    } catch (e) {
      _toastService.showError(
        'Failed to request approval: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Send work order to customer for approval (sales/admin)
  Future<String> sendToCustomer(
    int workOrderId, {
    String channel = 'email',
  }) async {
    try {
      final approvalResponse = await _workOrderApi.sendToCustomer(
        workOrderId,
        channel: channel,
      );
      
      // Get the public approval link
      final approvalLink = await _workOrderApi.getPublicApprovalLink(workOrderId);
      
      // Show toast with the approval link sent message
      _toastService.showSuccess(
        'Approval link sent to customer via $channel\n'
        'Public approval link: $approvalLink',
        duration: Duration(seconds: 8), // Longer duration for links
      );
      
      // For development, also log to console (sensitive data excluded)
      if (kDebugMode) {
        print('DEV CONSOLE: Approval link sent to customer');
        print('Channel: $channel');
        print('Link: $approvalLink');
        print('Expires: ${approvalResponse.expiresAt}');
      }
      
      return approvalLink;
    } catch (e) {
      _toastService.showError(
        'Failed to send approval to customer: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Open external approval page in browser/new tab
  Future<void> openApprovalPage(int workOrderId) async {
    try {
      final approvalLink = await _workOrderApi.getPublicApprovalLink(workOrderId);
      
      if (approvalLink.isNotEmpty) {
        // In a web environment, we can open in a new tab
        // For mobile, this would open in the default browser
        final Uri uri = Uri.parse(approvalLink);
        
        // Note: In Flutter web, this opens in a new tab
        // In mobile apps, this opens in the system browser
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch $approvalLink';
        }
        
        _toastService.showInfo(
          'Opening approval page for Work Order #$workOrderId',
        );
      } else {
        _toastService.showError(
          'No approval link available for this work order',
        );
      }
    } catch (e) {
      _toastService.showError(
        'Failed to open approval page: ${e.toString()}',
      );
    }
  }

  /// Start work order with media upload capability
  Future<WorkOrder> startWorkOrder(int workOrderId) async {
    try {
      final workOrder = await _workOrderApi.startWorkOrder(workOrderId);
      
      _toastService.showSuccess(
        'Work Order #${workOrder.id} started successfully',
      );
      
      return workOrder;
    } catch (e) {
      _toastService.showError(
        'Failed to start work order: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Finish work order with media upload capability
  Future<WorkOrder> finishWorkOrder(int workOrderId) async {
    try {
      final workOrder = await _workOrderApi.finishWorkOrder(workOrderId);
      
      _toastService.showSuccess(
        'Work Order #${workOrder.id} finished successfully',
      );
      
      return workOrder;
    } catch (e) {
      _toastService.showError(
        'Failed to finish work order: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Close work order
  Future<WorkOrder> closeWorkOrder(int workOrderId) async {
    try {
      final workOrder = await _workOrderApi.closeWorkOrder(workOrderId);
      
      _toastService.showSuccess(
        'Work Order #${workOrder.id} closed successfully',
      );
      
      return workOrder;
    } catch (e) {
      _toastService.showError(
        'Failed to close work order: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Upload media for work order (BEFORE/DURING/AFTER galleries)
  Future<void> uploadMedia(
    int workOrderId,
    String filePath,
    String phase, {
    String? note,
  }) async {
    try {
      final media = await _workOrderApi.uploadMedia(
        workOrderId,
        filePath,
        phase,
        note: note,
      );
      
      _toastService.showSuccess(
        '${phase.toUpperCase()} photo uploaded successfully',
      );
      
      // For development, log the uploaded media info
      if (kDebugMode) {
        print('DEV CONSOLE: Media uploaded');
        print('Work Order: $workOrderId');
        print('Phase: $phase');
        print('File: ${media.filename}');
        print('URL: ${media.url}');
      }
      
    } catch (e) {
      _toastService.showError(
        'Failed to upload ${phase.toLowerCase()} photo: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Get media galleries for work order
  Future<Map<String, List<dynamic>>> getWorkOrderGalleries(int workOrderId) async {
    try {
      final beforeGallery = await _workOrderApi.getBeforeGallery(workOrderId);
      final duringGallery = await _workOrderApi.getDuringGallery(workOrderId);
      final afterGallery = await _workOrderApi.getAfterGallery(workOrderId);
      
      return {
        'before': beforeGallery,
        'during': duringGallery,
        'after': afterGallery,
      };
    } catch (e) {
      _toastService.showError(
        'Failed to load work order galleries: ${e.toString()}',
      );
      rethrow;
    }
  }

}