import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { zodToJsonSchema } from 'zod-to-json-schema';
import {
  createAlertSchema,
  createAlertResponseSchema,
  createCircleSchema,
  createCircleResponseSchema,
  locationPingSchema,
  locationPingResponseSchema,
  sendOtpSchema,
  sendOtpResponseSchema,
  sosSchema,
  sosResponseSchema,
  verifyOtpSchema,
  verifyOtpResponseSchema
} from '../packages/schemas/src';

type OpenApiDocument = {
  openapi: '3.1.0';
  info: {
    title: string;
    version: string;
    description: string;
  };
  paths: Record<string, unknown>;
  components: {
    schemas: Record<string, unknown>;
  };
};

const createCircleRequestSchema = zodToJsonSchema(createCircleSchema, {
  $refStrategy: 'none'
});

const locationPingRequestSchema = zodToJsonSchema(locationPingSchema, {
  $refStrategy: 'none'
});

const sendOtpRequestSchema = zodToJsonSchema(sendOtpSchema, {
  $refStrategy: 'none'
});

const verifyOtpRequestSchema = zodToJsonSchema(verifyOtpSchema, {
  $refStrategy: 'none'
});

const createAlertRequestSchema = zodToJsonSchema(createAlertSchema, {
  $refStrategy: 'none'
});

const sosRequestSchema = zodToJsonSchema(sosSchema, {
  $refStrategy: 'none'
});

const createCircleResponseSchemaJson = zodToJsonSchema(createCircleResponseSchema, {
  $refStrategy: 'none'
});

const locationPingResponseSchemaJson = zodToJsonSchema(locationPingResponseSchema, {
  $refStrategy: 'none'
});

const sendOtpResponseSchemaJson = zodToJsonSchema(sendOtpResponseSchema, {
  $refStrategy: 'none'
});

const verifyOtpResponseSchemaJson = zodToJsonSchema(verifyOtpResponseSchema, {
  $refStrategy: 'none'
});

const createAlertResponseSchemaJson = zodToJsonSchema(createAlertResponseSchema, {
  $refStrategy: 'none'
});

const sosResponseSchemaJson = zodToJsonSchema(sosResponseSchema, {
  $refStrategy: 'none'
});

const examples = {
  createCircleRequest: {
    name: 'Family Circle',
    type: 'family',
    userId: 'user-1'
  },
  createCircleResponse: {
    id: 'circle-1',
    name: 'Family Circle',
    type: 'family',
    createdAt: '2026-04-05T12:00:00.000Z',
    members: ['user-1'],
    geofences: [
      {
        id: 'gf-home',
        lat: 37.7749,
        lng: -122.4194,
        radiusMeters: 120,
        name: 'Home'
      }
    ]
  },
  locationPingRequest: {
    userId: 'user-1',
    lat: 37.7749,
    lng: -122.4194,
    accuracy: 8,
    speed: 1.2,
    recordedAt: '2026-04-05T12:01:00.000Z'
  },
  locationPingResponse: {
    accepted: true,
    event: {
      userId: 'user-1',
      lat: 37.7749,
      lng: -122.4194,
      accuracy: 8,
      speed: 1.2,
      recordedAt: '2026-04-05T12:01:00.000Z',
      processedAt: '2026-04-05T12:01:01.250Z'
    },
    timestamp: '2026-04-05T12:01:01.250Z'
  },
  sendOtpRequest: {
    phone: '+14155552671'
  },
  sendOtpResponse: {
    sent: true
  },
  verifyOtpRequest: {
    phone: '+14155552671',
    code: '123456'
  },
  verifyOtpResponse: {
    token: 'eyJhbGciOi...'
  },
  createAlertRequest: {
    circleId: 'circle-1',
    userId: 'user-1',
    type: 'arrival',
    geofenceId: 'gf-home',
    message: 'Arrived at Home'
  },
  createAlertResponse: {
    id: 'alert-1',
    circleId: 'circle-1',
    userId: 'user-1',
    type: 'arrival',
    geofenceId: 'gf-home',
    message: 'Arrived at Home',
    createdAt: '2026-04-05T12:02:00.000Z',
    acknowledged: false
  },
  sosRequest: {
    userId: 'user-1',
    circleId: 'circle-1',
    lat: 37.775,
    lng: -122.4195
  },
  sosResponse: {
    accepted: true,
    type: 'sos',
    alert: {
      id: 'alert-sos-1',
      circleId: 'circle-1',
      userId: 'user-1',
      type: 'sos',
      message: 'SOS triggered',
      createdAt: '2026-04-05T12:03:00.000Z',
      acknowledged: false
    }
  }
};

const doc: OpenApiDocument = {
  openapi: '3.1.0',
  info: {
    title: 'DreamFlow API Contracts (Generated)',
    version: '0.1.0',
    description:
      'Static OpenAPI artifact generated from shared Zod contracts in packages/schemas.'
  },
  paths: {
    '/v1/circles': {
      post: {
        summary: 'Create circle',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateCircleRequest' },
              example: examples.createCircleRequest
            }
          }
        },
        responses: {
          '201': {
            description: 'Circle created',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/CreateCircleResponse' },
                example: examples.createCircleResponse
              }
            }
          },
          '400': {
            description: 'Validation failure'
          }
        }
      }
    },
    '/v1/presence/location': {
      post: {
        summary: 'Ingest location ping',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/LocationPingRequest' },
              example: examples.locationPingRequest
            }
          }
        },
        responses: {
          '201': {
            description: 'Location accepted',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/LocationPingResponse' },
                example: examples.locationPingResponse
              }
            }
          },
          '400': {
            description: 'Validation failure'
          }
        }
      }
    },
    '/v1/auth/phone/send-otp': {
      post: {
        summary: 'Send OTP to phone number',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/SendOtpRequest' },
              example: examples.sendOtpRequest
            }
          }
        },
        responses: {
          '200': {
            description: 'OTP send accepted',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/SendOtpResponse' },
                example: examples.sendOtpResponse
              }
            }
          },
          '400': {
            description: 'Validation failure'
          }
        }
      }
    },
    '/v1/auth/phone/verify-otp': {
      post: {
        summary: 'Verify OTP and issue auth token',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/VerifyOtpRequest' },
              example: examples.verifyOtpRequest
            }
          }
        },
        responses: {
          '200': {
            description: 'Verification succeeded',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/VerifyOtpResponse' },
                example: examples.verifyOtpResponse
              }
            }
          },
          '401': {
            description: 'Invalid or expired code'
          }
        }
      }
    },
    '/v1/alerts': {
      post: {
        summary: 'Create alert event',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/CreateAlertRequest' },
              example: examples.createAlertRequest
            }
          }
        },
        responses: {
          '201': {
            description: 'Alert created',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/CreateAlertResponse' },
                example: examples.createAlertResponse
              }
            }
          },
          '400': {
            description: 'Validation failure'
          }
        }
      }
    },
    '/v1/alerts/sos': {
      post: {
        summary: 'Trigger SOS alert',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/SosRequest' },
              example: examples.sosRequest
            }
          }
        },
        responses: {
          '201': {
            description: 'SOS accepted',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/SosResponse' },
                example: examples.sosResponse
              }
            }
          },
          '400': {
            description: 'Validation failure'
          }
        }
      }
    }
  },
  components: {
    schemas: {
      CreateCircleRequest: createCircleRequestSchema,
      LocationPingRequest: locationPingRequestSchema,
      SendOtpRequest: sendOtpRequestSchema,
      VerifyOtpRequest: verifyOtpRequestSchema,
      CreateAlertRequest: createAlertRequestSchema,
      SosRequest: sosRequestSchema,
      CreateCircleResponse: createCircleResponseSchemaJson,
      LocationPingResponse: locationPingResponseSchemaJson,
      SendOtpResponse: sendOtpResponseSchemaJson,
      VerifyOtpResponse: verifyOtpResponseSchemaJson,
      CreateAlertResponse: createAlertResponseSchemaJson,
      SosResponse: sosResponseSchemaJson
    }
  }
};

const outputPath = resolve(process.cwd(), 'docs/openapi.generated.json');
mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, `${JSON.stringify(doc, null, 2)}\n`, 'utf8');

console.log(`Generated OpenAPI contract artifact: ${outputPath}`);
