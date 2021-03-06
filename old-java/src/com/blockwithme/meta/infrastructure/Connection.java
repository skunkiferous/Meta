/*
 * Copyright (C) 2013 Sebastien Diot.
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
package com.blockwithme.meta.infrastructure;

import java.net.URL;

import com.blockwithme.meta.types.Named;
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * Represents a network connection.
 *
 * @author monster
 */
@TypeValue("Connection")
public interface Connection extends Named {
    /** Returns an URL used to create this connection. */
    @Property("url")
    URL getUrl();

    /** Sets an URL used to create this connection. */
    @Property("url")
    void setUrl(final URL url);

    // TODO
}
