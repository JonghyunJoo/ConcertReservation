package com.example.paymentservice.event;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class PaymentSuccessEvent {
    private Long userId;
    private Long amount;
}
