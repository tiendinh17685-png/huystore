// Enum mới cho trạng thái xử lý của step/detail, chỉ còn 2 trạng thái.
import 'package:flutter/material.dart';

enum ProcessingStatus {
  Unfinished(1),
  Finished(2);

  const ProcessingStatus(this.value);
  final int value;
}

enum OrderStatusId {
  waitingConfirm(1),
  getting(2),
  received(3),
  checking(4),
  quotingPrice(5),
  waitingConfirmPrice(6),
  confirmPrice(8),
  editing(9),
  fixedWaitingDelivery(11),
  delivering(12),
  completedDelivered(13),
  customerRefusedNotRepair(14);

  final int id;
  const OrderStatusId(this.id);
}
