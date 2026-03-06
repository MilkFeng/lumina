export interface Point {
    x: number;
    y: number;
}

export interface RectLike {
    x: number;
    y: number;
    width: number;
    height: number;

    contains(point?: Point | null): boolean;
    intersects(other?: RectLike | null): boolean;
}

export interface QuadTreeItem {
    rect: RectLike;
}

export class Rect implements RectLike {
    public x: number;
    public y: number;
    public width: number;
    public height: number;

    constructor(x: number = 0, y: number = 0, width: number = 0, height: number = 0) {
        this.x = x || 0;
        this.y = y || 0;
        this.width = Math.max(0, width || 0);
        this.height = Math.max(0, height || 0);
    }

    public contains(point?: Point | null): boolean {
        if (!point) return false;
        return (
            point.x >= this.x &&
            point.x <= this.x + this.width &&
            point.y >= this.y &&
            point.y <= this.y + this.height
        );
    }

    public intersects(other?: RectLike | null): boolean {
        if (!other) return false;
        return !(
            other.x > this.x + this.width ||
            other.x + other.width < this.x ||
            other.y > this.y + this.height ||
            other.y + other.height < this.y
        );
    }
}

export class QuadTree<T extends QuadTreeItem> {
    public boundary: Rect;
    public capacity: number;
    public items: T[];
    public divided: boolean;

    public northwest: QuadTree<T> | null = null;
    public northeast: QuadTree<T> | null = null;
    public southwest: QuadTree<T> | null = null;
    public southeast: QuadTree<T> | null = null;

    constructor(boundary: Rect, capacity: number = 4) {
        this.boundary = boundary;
        this.capacity = Math.max(1, capacity || 4);
        this.items = [];
        this.divided = false;
    }

    private toRect(rawRect?: RectLike | null): Rect | null {
        if (!rawRect) return null;
        return new Rect(rawRect.x, rawRect.y, rawRect.width, rawRect.height);
    }

    private subdivide(): void {
        const x = this.boundary.x;
        const y = this.boundary.y;
        const w = this.boundary.width / 2;
        const h = this.boundary.height / 2;

        this.northwest = new QuadTree<T>(new Rect(x, y, w, h), this.capacity);
        this.northeast = new QuadTree<T>(new Rect(x + w, y, w, h), this.capacity);
        this.southwest = new QuadTree<T>(new Rect(x, y + h, w, h), this.capacity);
        this.southeast = new QuadTree<T>(new Rect(x + w, y + h, w, h), this.capacity);
        this.divided = true;
    }

    public insert(item?: T | null): boolean {
        if (!item || !item.rect) return false;

        const rect = this.toRect(item.rect);
        if (!rect || !this.boundary.intersects(rect)) return false;

        if (!this.divided && this.items.length < this.capacity) {
            this.items.push(item);
            return true;
        }

        if (!this.divided) {
            this.subdivide();
            const existing = this.items;
            this.items = [];
            for (let i = 0; i < existing.length; i++) {
                this.insertIntoChildren(existing[i]);
            }
        }

        return this.insertIntoChildren(item);
    }

    private insertIntoChildren(item: T): boolean {
        let inserted = false;
        if (this.northwest!.insert(item)) inserted = true;
        if (this.northeast!.insert(item)) inserted = true;
        if (this.southwest!.insert(item)) inserted = true;
        if (this.southeast!.insert(item)) inserted = true;
        return inserted;
    }

    public query(range?: RectLike | null, found: T[] = []): T[] {
        if (!range || !this.boundary.intersects(range)) return found;

        for (let i = 0; i < this.items.length; i++) {
            const item = this.items[i];
            const rect = this.toRect(item.rect);
            if (rect && range.intersects(rect)) {
                found.push(item);
            }
        }

        if (this.divided) {
            this.northwest!.query(range, found);
            this.northeast!.query(range, found);
            this.southwest!.query(range, found);
            this.southeast!.query(range, found);
        }

        return found;
    }
}