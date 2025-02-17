--
-- Copyright The OpenZipkin Authors
-- SPDX-License-Identifier: Apache-2.0
--

CREATE TABLE IF NOT EXISTS zipkin_spans (
                                            `trace_id_high` BIGINT NOT NULL DEFAULT 0 COMMENT 'If non zero, this means the trace uses 128 bit traceIds instead of 64 bit',
                                            `trace_id` BIGINT NOT NULL,
                                            `id` BIGINT NOT NULL,
                                            `name` VARCHAR(255) NOT NULL,
    `remote_service_name` VARCHAR(255),
    `parent_id` BIGINT,
    `debug` BOOLEAN,
    `start_ts` BIGINT COMMENT 'Span.timestamp(): epoch micros used for endTs query and to implement TTL',
    `duration` BIGINT COMMENT 'Span.duration(): micros used for minDuration and maxDuration query',
    PRIMARY KEY (`trace_id_high`, `trace_id`, `id`)
    ) ENGINE=InnoDB CHARACTER SET=utf8 COLLATE=utf8_general_ci;

ALTER TABLE zipkin_spans ADD INDEX `idx_trace` (`trace_id_high`, `trace_id`) COMMENT 'for getTracesByIds';
ALTER TABLE zipkin_spans ADD INDEX `idx_name` (`name`) COMMENT 'for getTraces and getSpanNames';
ALTER TABLE zipkin_spans ADD INDEX `idx_remote_service_name` (`remote_service_name`) COMMENT 'for getTraces and getRemoteServiceNames';
ALTER TABLE zipkin_spans ADD INDEX `idx_start_ts` (`start_ts`) COMMENT 'for getTraces ordering and range';

CREATE TABLE IF NOT EXISTS zipkin_annotations (
                                                  `trace_id_high` BIGINT NOT NULL DEFAULT 0 COMMENT 'If non zero, this means the trace uses 128 bit traceIds instead of 64 bit',
                                                  `trace_id` BIGINT NOT NULL COMMENT 'coincides with zipkin_spans.trace_id',
                                                  `span_id` BIGINT NOT NULL COMMENT 'coincides with zipkin_spans.id',
                                                  `a_key` VARCHAR(255) NOT NULL COMMENT 'BinaryAnnotation.key or Annotation.value if type == -1',
    `a_value` BLOB COMMENT 'BinaryAnnotation.value(), which must be smaller than 64KB',
    `a_type` INT NOT NULL COMMENT 'BinaryAnnotation.type() or -1 if Annotation',
    `a_timestamp` BIGINT COMMENT 'Used to implement TTL; Annotation.timestamp or zipkin_spans.timestamp',
    `endpoint_ipv4` VARBINARY(16) COMMENT 'Stores IPv4 as binary',
    `endpoint_ipv6` BINARY(16) COMMENT 'Null when Binary/Annotation.endpoint is null, or no IPv6 address',
    `endpoint_port` SMALLINT COMMENT 'Null when Binary/Annotation.endpoint is null',
    `endpoint_service_name` VARCHAR(255) COMMENT 'Null when Binary/Annotation.endpoint is null',
    PRIMARY KEY (`trace_id_high`, `trace_id`, `span_id`, `a_key`, `a_timestamp`)
    ) ENGINE=InnoDB CHARACTER SET=utf8 COLLATE=utf8_general_ci;

ALTER TABLE zipkin_annotations ADD INDEX `idx_annotations_trace` (`trace_id_high`, `trace_id`, `span_id`) COMMENT 'for joining with zipkin_spans';
ALTER TABLE zipkin_annotations ADD INDEX `idx_annotations_trace_id` (`trace_id_high`, `trace_id`) COMMENT 'for getTraces/ByIds';
ALTER TABLE zipkin_annotations ADD INDEX `idx_annotations_service_name` (`endpoint_service_name`) COMMENT 'for getTraces and getServiceNames';
ALTER TABLE zipkin_annotations ADD INDEX `idx_annotations_type` (`a_type`) COMMENT 'for getTraces and autocomplete values';
ALTER TABLE zipkin_annotations ADD INDEX `idx_annotations_key` (`a_key`) COMMENT 'for getTraces and autocomplete values';
ALTER TABLE zipkin_annotations ADD INDEX `idx_dependencies` (`trace_id`, `span_id`, `a_key`) COMMENT 'for dependencies job';

CREATE TABLE IF NOT EXISTS zipkin_dependencies (
                                                   `day` DATE NOT NULL,
                                                   `parent` VARCHAR(255) NOT NULL,
    `child` VARCHAR(255) NOT NULL,
    `call_count` BIGINT,
    `error_count` BIGINT,
    PRIMARY KEY (`day`, `parent`, `child`)
    ) ENGINE=InnoDB CHARACTER SET=utf8 COLLATE=utf8_general_ci;
