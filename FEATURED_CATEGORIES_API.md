# Featured Categories API Guide

## Overview

The Featured Categories system is **completely separate** from the main category/subcategory structure. It allows you to create promotional sections with flexible display layouts (banner, 2-column grid, 4-column grid) that can be shown/hidden with a simple toggle.

### Key Concepts

| Entity | Description |
|--------|-------------|
| **Featured Category** | A promotional category with a banner image and layout type |
| **Featured Subcategory** | Optional subcategories under a featured category |
| **Featured Category Item** | Links existing items (from main items table) to featured categories/subcategories |

### Layout Types

| Type | Description | Use Case |
|------|-------------|----------|
| `banner` | Single full-width display | Hero promotions, top banners |
| `grid_2` | 2-column grid | Brand showcases (like MINISO/Dior example) |
| `grid_4` | 4-column grid | Smaller category tiles |

---

## API Endpoints

### Base URL
```
/api/featured-categories
/api/featured-subcategories
/api/featured-category-items
```

---

## 1. Featured Categories

### List All Featured Categories

```http
GET /api/featured-categories
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `all` | boolean | `false` | Include hidden (is_active=false) categories |

**Response:**
```json
[
  {
    "id": 1,
    "name_en": "Original Perfumes",
    "name_ku": "بۆنی ئۆریجیناڵ",
    "name_ar": "عطور أصلية",
    "description": "Up to 50% off",
    "image_url": "/uploads/featured-categories/1702134567890.jpg",
    "layout_type": "grid_2",
    "display_order": 1,
    "is_active": true,
    "created_at": "2025-12-09T10:00:00.000Z",
    "updated_at": "2025-12-09T10:00:00.000Z"
  },
  {
    "id": 2,
    "name_en": "Skin Care Products",
    "name_ku": "بەرهەمەکانی گرنگیدان بە پێست",
    "name_ar": "منتجات العناية بالبشرة",
    "description": null,
    "image_url": "/uploads/featured-categories/1702134567891.jpg",
    "layout_type": "banner",
    "display_order": 0,
    "is_active": true,
    "created_at": "2025-12-09T10:00:00.000Z",
    "updated_at": "2025-12-09T10:00:00.000Z"
  }
]
```

**Note:** Results are sorted by `display_order ASC`, then by `id ASC`. Lower display_order appears first.

---

### List All Featured Categories WITH Items

```http
GET /api/featured-categories/with-items
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `all` | boolean | `false` | Include hidden categories and subcategories |

**Response:**
```json
[
  {
    "id": 1,
    "name_en": "Original Perfumes",
    "name_ku": "بۆنی ئۆریجیناڵ",
    "name_ar": "عطور أصلية",
    "description": "Up to 50% off",
    "image_url": "/uploads/featured-categories/1702134567890.jpg",
    "layout_type": "grid_2",
    "display_order": 1,
    "is_active": true,
    "subcategories": [
      {
        "id": 1,
        "name_en": "Men's Perfumes",
        "name_ku": "بۆنی پیاوان",
        "name_ar": "عطور رجالية",
        "display_order": 0,
        "is_active": true,
        "subcategoryItems": [
          {
            "id": 5,
            "item_id": 42,
            "display_order": 0,
            "item": {
              "id": 42,
              "name_en": "Dior Sauvage",
              "name_ku": "دیۆر ساڤاج",
              "price": "150.00",
              "image_url": "/uploads/items/dior.jpg",
              "stock": 25
            }
          }
        ]
      }
    ],
    "categoryItems": [
      {
        "id": 1,
        "item_id": 15,
        "display_order": 0,
        "item": {
          "id": 15,
          "name_en": "Chanel Bleu",
          "name_ku": "شانێل بلو",
          "price": "180.00",
          "image_url": "/uploads/items/chanel.jpg",
          "stock": 10
        }
      }
    ]
  }
]
```

**Important:**
- `categoryItems` = Items linked directly to the featured category
- `subcategoryItems` = Items linked through subcategories
- A featured category can have BOTH direct items AND subcategories with items

---

### Get Single Featured Category

```http
GET /api/featured-categories/:id
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `all` | boolean | `false` | Include hidden subcategories |

Returns the featured category with all its subcategories and items (same structure as above).

---

### Create Featured Category

```http
POST /api/featured-categories
```

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name_en` | string | Yes | English name |
| `name_ku` | string | No | Kurdish name |
| `name_ar` | string | No | Arabic name |
| `description` | string | No | Description text |
| `image` | file | No | Banner/card image |
| `layout_type` | enum | No | `banner`, `grid_2`, `grid_4` (default: `banner`) |
| `display_order` | integer | No | Sort order (default: 0) |
| `is_active` | boolean | No | Show/hide toggle (default: true) |

**Response:** `201 Created`
```json
{
  "id": 3,
  "name_en": "New Arrivals",
  "name_ku": "",
  "name_ar": "",
  "description": null,
  "image_url": "/uploads/featured-categories/1702134567892.jpg",
  "layout_type": "banner",
  "display_order": 0,
  "is_active": true,
  "created_at": "2025-12-09T12:00:00.000Z",
  "updated_at": "2025-12-09T12:00:00.000Z"
}
```

---

### Update Featured Category

```http
PUT /api/featured-categories/:id
```

**Authentication:** Required

**Content-Type:** `multipart/form-data`

**Body:** Same as create (all fields optional for update)

**Response:** `200 OK` - Returns updated category

---

### Toggle Featured Category Active Status

```http
PATCH /api/featured-categories/:id/toggle
```

**Authentication:** Required

Toggles `is_active` between `true` and `false`.

**Response:** `200 OK`
```json
{
  "id": 1,
  "is_active": false,
  "..."
}
```

---

### Delete Featured Category

```http
DELETE /api/featured-categories/:id
```

**Authentication:** Required

**Response:** `204 No Content`

**Note:** Deleting a featured category will CASCADE delete all its subcategories and item links.

---

## 2. Featured Subcategories

### List Subcategories by Category

```http
GET /api/featured-categories/:categoryId/subcategories
```

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| `all` | boolean | `false` | Include hidden subcategories |

**Response:**
```json
[
  {
    "id": 1,
    "featured_category_id": 1,
    "name_en": "Men's Perfumes",
    "name_ku": "بۆنی پیاوان",
    "name_ar": "عطور رجالية",
    "description": null,
    "display_order": 0,
    "is_active": true,
    "created_at": "2025-12-09T10:00:00.000Z",
    "updated_at": "2025-12-09T10:00:00.000Z"
  }
]
```

---

### Get Single Subcategory (with items)

```http
GET /api/featured-subcategories/:id
```

**Response:**
```json
{
  "id": 1,
  "featured_category_id": 1,
  "name_en": "Men's Perfumes",
  "name_ku": "بۆنی پیاوان",
  "name_ar": "عطور رجالية",
  "description": null,
  "display_order": 0,
  "is_active": true,
  "featuredCategory": {
    "id": 1,
    "name_en": "Original Perfumes",
    "layout_type": "grid_2"
  },
  "subcategoryItems": [
    {
      "id": 5,
      "item_id": 42,
      "display_order": 0,
      "item": {
        "id": 42,
        "name_en": "Dior Sauvage",
        "price": "150.00"
      }
    }
  ]
}
```

---

### Create Subcategory

```http
POST /api/featured-categories/:categoryId/subcategories
```

**Authentication:** Required

**Content-Type:** `application/json`

**Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name_en` | string | Yes | English name |
| `name_ku` | string | No | Kurdish name |
| `name_ar` | string | No | Arabic name |
| `description` | string | No | Description text |
| `display_order` | integer | No | Sort order (default: 0) |
| `is_active` | boolean | No | Show/hide toggle (default: true) |

**Response:** `201 Created`

---

### Update Subcategory

```http
PUT /api/featured-subcategories/:id
```

**Authentication:** Required

**Body:** Same as create (all fields optional)

---

### Toggle Subcategory Active Status

```http
PATCH /api/featured-subcategories/:id/toggle
```

**Authentication:** Required

---

### Delete Subcategory

```http
DELETE /api/featured-subcategories/:id
```

**Authentication:** Required

**Response:** `204 No Content`

---

## 3. Featured Category Items (Linking Items)

### Add Item to Featured Category (Direct)

```http
POST /api/featured-categories/:id/items
```

**Authentication:** Required

**Body:**
```json
{
  "item_id": 42,
  "display_order": 0
}
```

**Response:** `201 Created`
```json
{
  "id": 10,
  "item_id": 42,
  "featured_category_id": 1,
  "featured_subcategory_id": null,
  "display_order": 0,
  "item": {
    "id": 42,
    "name_en": "Dior Sauvage",
    "price": "150.00"
  }
}
```

---

### Add Item to Featured Subcategory

```http
POST /api/featured-subcategories/:id/items
```

**Authentication:** Required

**Body:**
```json
{
  "item_id": 42,
  "display_order": 0
}
```

---

### Remove Item Link

```http
DELETE /api/featured-category-items/:id
```

**Authentication:** Required

**Response:** `204 No Content`

**Note:** This removes the link, NOT the actual item from your inventory.

---

### Update Item Display Order

```http
PUT /api/featured-category-items/:id/order
```

**Authentication:** Required

**Body:**
```json
{
  "display_order": 5
}
```

---

### List All Item Links (Admin)

```http
GET /api/featured-category-items
```

Returns all item links with their associated item, category, and subcategory details.

---

## Frontend Implementation Guide

### For Mobile App (Home Screen)

```javascript
// Fetch all active featured categories with items
const response = await fetch('/api/featured-categories/with-items');
const featuredCategories = await response.json();

// Render based on layout_type
featuredCategories.forEach(category => {
  switch(category.layout_type) {
    case 'banner':
      renderBanner(category);  // Full-width promotional banner
      break;
    case 'grid_2':
      renderGrid2(category);   // 2-column grid (like MINISO/Dior example)
      break;
    case 'grid_4':
      renderGrid4(category);   // 4-column grid
      break;
  }
});
```

### For Dashboard (Admin Panel)

**CRUD Flow:**
1. **List** -> `GET /api/featured-categories?all=true` (include hidden)
2. **Create** -> `POST /api/featured-categories` with FormData
3. **Edit** -> `PUT /api/featured-categories/:id`
4. **Toggle visibility** -> `PATCH /api/featured-categories/:id/toggle`
5. **Delete** -> `DELETE /api/featured-categories/:id`

**Adding Items Flow:**
1. Show item picker (from existing items: `GET /api/items`)
2. Link item -> `POST /api/featured-categories/:id/items` or `POST /api/featured-subcategories/:id/items`
3. Reorder -> `PUT /api/featured-category-items/:id/order`
4. Remove -> `DELETE /api/featured-category-items/:id`

---

## Error Responses

| Status | Description |
|--------|-------------|
| `400` | Bad request (missing required fields, duplicate link) |
| `401` | Unauthorized (authentication required) |
| `404` | Not found (category, subcategory, or item doesn't exist) |
| `500` | Server error |

**Example Error:**
```json
{
  "error": "Item already linked to this category"
}
```

---

## Display Order Logic

- Lower `display_order` values appear **first**
- Use `0, 1, 2, 3...` for sequential ordering
- To reorder, update the `display_order` values

---

## Database Schema Reference

### featured_categories
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED | Primary key |
| name_en | VARCHAR(191) | English name (required) |
| name_ku | VARCHAR(191) | Kurdish name |
| name_ar | VARCHAR(191) | Arabic name |
| description | TEXT | Optional description |
| image_url | VARCHAR(255) | Banner/card image path |
| layout_type | ENUM | 'banner', 'grid_2', 'grid_4' |
| display_order | INT | Sort order |
| is_active | BOOLEAN | Show/hide toggle |

### featured_subcategories
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED | Primary key |
| featured_category_id | INT UNSIGNED | FK to featured_categories |
| name_en | VARCHAR(191) | English name (required) |
| name_ku | VARCHAR(191) | Kurdish name |
| name_ar | VARCHAR(191) | Arabic name |
| description | TEXT | Optional description |
| display_order | INT | Sort order |
| is_active | BOOLEAN | Show/hide toggle |

### featured_category_items
| Column | Type | Description |
|--------|------|-------------|
| id | INT UNSIGNED | Primary key |
| item_id | INT UNSIGNED | FK to items table (required) |
| featured_category_id | INT UNSIGNED | FK to featured_categories (nullable) |
| featured_subcategory_id | INT UNSIGNED | FK to featured_subcategories (nullable) |
| display_order | INT | Sort order |

**Note:** Either `featured_category_id` OR `featured_subcategory_id` must be set (at least one).

