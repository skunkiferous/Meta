/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.beans.impl;

import com.blockwithme.meta.Type;
import com.blockwithme.meta.beans.EntityContext;
import com.blockwithme.meta.beans._Entity;

/**
 * Base class for entities.
 *
 * @author monster
 */
abstract class _EntityImpl extends _BeanImpl implements _Entity {
    /**
     * @param type
     */
    new(Type<?> type) {
        super(type);
    }

    /** The EntityContext of this Entity */
    var EntityContext entityContext;

    /** The creation time of this Entity */
    var long creationTime;

    /** The last modification time of this Entity */
    var long lastModificationTime;

    override final EntityContext getEntityContext() {
        return entityContext;
    }

    override final void setEntityContext(EntityContext entityContext) {
        this.entityContext = entityContext;
    }

    override final long getCreationTime() {
        return creationTime;
    }

    override final void setCreationTime(long creationTime) {
        this.creationTime = creationTime;
    }

    override final long getLastModificationTime() {
        return lastModificationTime;
    }

    override final void setLastModificationTime(long lastModificationTime) {
        this.lastModificationTime = lastModificationTime;
    }

    /** Make a new instance of the same type as self. */
    protected override _BeanImpl newInstance() {
        val result = super.newInstance() as _EntityImpl;
        result.entityContext = entityContext;
        result.creationTime = creationTime;
        result.lastModificationTime = lastModificationTime;
        return result;
    }
}
