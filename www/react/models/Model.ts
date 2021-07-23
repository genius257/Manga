export default class Model {
    attributes = {}

    getAttribute(key : string) {
        // If the attribute exists in the attribute array or has a "get" mutator we will
        // get the attribute's value. Otherwise, we will proceed as if the developers
        // are asking for a relationship's value. This covers both types of values.
        if (this.attributes.hasOwnProperty(key) ||
            this.casts.hasOwnProperty(key) ||
            this.hasGetMutator(key) ||
            this.isClassCastable(key)) {
            return this.getAttributeValue(key);
        }

        // Here we will determine if the model base class itself contains this given key
        // since we don't want to treat any of those methods as relationships because
        // they are all intended as helper methods and none of these are relations.
        if (this.hasOwnProperty(key) && typeof this[key] === "function") {
            return;
        }

        return this.getRelationValue(key);
    }

    getAttributeValue(key: string) {
        return this.transformModelValue(key, this.getAttributeFromArray(key));
    }

    getAttributeFromArray(key: string) {
        return this.getAttributes()[key] || null;//FIXME: ?? null
    }

    getAttributes() {
        this.mergeAttributesFromClassCasts();

        return this.attributes;
    }

    getRelationValue(key: string) {
        // If the key already exists in the relationships array, it just means the
        // relationship has already been loaded, so we'll just return it out of
        // here because there is no need to query within the relations twice.
        if (this.relationLoaded(key)) {
            return this.relations[key];
        }

        // If the "attribute" exists as a method on the model, we will just assume
        // it is a relationship and will load and return results from the query
        // and hydrate the relationship's value on the "relationships" array.
        if ((this.hasOwnProperty(key) && typeof this[key] === "function") ||
            (this.constructor.$relationResolvers[this.constructor.name][key])) {
            return this.getRelationshipFromMethod(key);
        }
    }

    getRelationshipFromMethod(method: string) {
        throw new Error("Not implemented");
        /*
        const relation = this[method]();

        if (! relation instanceof Relation) {
            if (is_null($relation)) {
                throw new LogicException(sprintf(
                    '%s::%s must return a relationship instance, but "null" was returned. Was the "return" keyword used?', static::class, $method
                ));
            }

            throw new LogicException(sprintf(
                '%s::%s must return a relationship instance.', static::class, $method
            ));
        }

        return tap(relation.getResults(), function (results) {
            this.setRelation(method, results);
        });
        */
    }

    protected castAttribute(key: string, value: any) {
        throw new Error("Not implemented");
        /*
        const castType = this.getCastType(key);

        if (is_null(value) && in_array(castType, static::$primitiveCastTypes)) {
            return value;
        }

        switch (castType) {
            case 'int':
            case 'integer':
                return (int) $value;
            case 'real':
            case 'float':
            case 'double':
                return $this->fromFloat($value);
            case 'decimal':
                return $this->asDecimal($value, explode(':', $this->getCasts()[$key], 2)[1]);
            case 'string':
                return (string) $value;
            case 'bool':
            case 'boolean':
                return (bool) $value;
            case 'object':
                return $this->fromJson($value, true);
            case 'array':
            case 'json':
                return $this->fromJson($value);
            case 'collection':
                return new BaseCollection($this->fromJson($value));
            case 'date':
                return $this->asDate($value);
            case 'datetime':
            case 'custom_datetime':
                return $this->asDateTime($value);
            case 'timestamp':
                return $this->asTimestamp($value);
        }

        if ($this->isClassCastable($key)) {
            return $this->getClassCastableAttributeValue($key, $value);
        }

        return $value;
        */
    }

    relationLoaded(key: string): boolean {
        return this.relations.hasOwnProperty(key);
    }

    protected mergeAttributesFromClassCasts() {
        throw new Error("Not implemented");
        /*
        for (const [key, value] of Object.entries(this.classCastCache)) {
            const caster = this.resolveCasterClass(key);

            this.attributes = Object.assign({},
                this.attributes,
                caster instanceof CastsInboundAttributes
                       ? {[key]: value}
                       : this.normalizeCastClassResponse(key, caster.set(this, key, value, this.attributes))
            );
        }
        */
    }
}
