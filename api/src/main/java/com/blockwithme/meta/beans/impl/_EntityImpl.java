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
public abstract class _EntityImpl extends _BeanImpl implements _Entity {
    /**
     * @param type
     */
    public _EntityImpl(final Type<?> type) {
        super(type);
    }

    /** The EntityContext of this Entity */
    private EntityContext entityContext;

    /** The creation time of this Entity */
    private long creationTime;

    /** The last modification time of this Entity */
    private long lastModificationTime;

    @Override
    public final EntityContext getEntityContext() {
        return entityContext;
    }

    @Override
    public final void setEntityContext(final EntityContext entityContext) {
        this.entityContext = entityContext;
    }

    @Override
    public final long getCreationTime() {
        return creationTime;
    }

    @Override
    public final void setCreationTime(final long creationTime) {
        this.creationTime = creationTime;
    }

    @Override
    public final long getLastModificationTime() {
        return lastModificationTime;
    }

    @Override
    public final void setLastModificationTime(final long lastModificationTime) {
        this.lastModificationTime = lastModificationTime;
    }

    /** Copy the "non-property" data. */
    @Override
    protected void copyOtherData(final _BeanImpl result) {
        super.copyOtherData(result);
        final _EntityImpl entity = (_EntityImpl) result;
        entity.entityContext = entityContext;
        entity.creationTime = creationTime;
        entity.lastModificationTime = lastModificationTime;
    }
}
