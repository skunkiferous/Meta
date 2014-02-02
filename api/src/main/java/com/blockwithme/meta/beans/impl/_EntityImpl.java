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

import com.blockwithme.meta.beans.EntityContext;
import com.blockwithme.meta.beans._Entity;

/**
 * Base class for entities.
 *
 * @author monster
 */
public class _EntityImpl extends _BeanImpl implements _Entity {
    /** The EntityContext of this Entity */
    private EntityContext entityContext;

    /** The creation time of this Entity */
    private long creationTime;

    /** The last modification time of this Entity */
    private long lastModificationTime;

    public final EntityContext getEntityContext() {
        return entityContext;
    }

    public final void setEntityContext(final EntityContext entityContext) {
        this.entityContext = entityContext;
    }

    public final long getCreationTime() {
        return creationTime;
    }

    public final void setCreationTime(final long creationTime) {
        this.creationTime = creationTime;
    }

    public final long getLastModificationTime() {
        return lastModificationTime;
    }

    public final void setLastModificationTime(final long lastModificationTime) {
        this.lastModificationTime = lastModificationTime;
    }
}
