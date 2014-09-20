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

import com.blockwithme.meta.Type
import com.blockwithme.meta.beans.Handle
import com.blockwithme.meta.beans._Entity

/**
 * Base class for entities.
 *
 * @author monster
 */
abstract class _EntityImpl extends _BeanImpl implements _Entity {
    /** The Handle */
    var volatile Handle handle

    /** The creation time of this Entity */
    var long creationTime;

    /** The last modification time of this Entity */
    var long lastModificationTime;

    /**
     * @param type
     */
    new(Type<?> type) {
        super(type);
    }

	override final Handle getHandle() {
		if (handle == null) {
			throw new IllegalStateException("Handle not initialized")
		}
		handle
	}

	override final void setHandle(Handle handle) {
		if (handle == null) {
			throw new IllegalArgumentException("Handle cannot be null")
		}
		if (this.handle != null) {
			throw new IllegalStateException("Handle already set")
		}
		this.handle = handle
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
        // TODO If it has the same Handle, then it is the same Entity;
        // Is that really what we want to do?
        result.handle = handle;
        result.creationTime = creationTime;
        result.lastModificationTime = lastModificationTime;
        return result;
    }
}
