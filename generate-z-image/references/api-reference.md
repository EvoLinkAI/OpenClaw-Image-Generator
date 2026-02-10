# Evolink Z-Image-Turbo API Reference

## Base URL

`https://api.evolink.ai/v1`

## Authentication

All requests require a Bearer token in the `Authorization` header:
```
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### POST /images/generations

Submit an image generation task.

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| model | string | Yes | Must be `"z-image-turbo"` |
| prompt | string | Yes | Image description, max 2000 chars |
| size | string | No | Aspect ratio, default `"1:1"` |
| seed | integer | No | Random seed (1-2147483647) |
| nsfw_check | boolean | No | Stricter NSFW filtering, default `false` |

**Size Options:** `"1:1"`, `"2:3"`, `"3:2"`, `"3:4"`, `"4:3"`, `"9:16"`, `"16:9"`, `"1:2"`, `"2:1"`, or custom `"WxH"` (376-1536px)

**Response:** Returns a task object with `id` field.

### GET /tasks/{task_id}

Poll for task status.

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| status | string | `"pending"`, `"processing"`, `"completed"`, or `"failed"` |
| results | array | Image URLs (available when `completed`) |

**Note:** Image URLs expire in **72 hours**.
