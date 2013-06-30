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

import com.blockwithme.meta.TypedVertex;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * Life, the Universe and Everything!
 *
 * Everything is the root of everything in "meta".
 * It gives access to both static and dynamic information.
 *
 * We assume HostingProviders are statically configured...
 *
 * @author monster
 */
@TypeValue("Everything")
public interface Everything extends TypedVertex {
    /** The process in which the code is currently executing ...*/
    @Adjacency(label = "currentProcess")
    Process getCurrentProcess();

    /** Sets the process in which the code is currently executing ...*/
    @Adjacency(label = "currentProcess")
    void setCurrentProcess(final Process currentProcess);

    /** The known HostingProviders; the root of the infrastructure. */
    @Adjacency(label = "knows")
    HostingProvider[] getProviders();

    /** Adds a HostingProvider. */
    @Adjacency(label = "knows")
    void addHostingProvider(final HostingProvider region);

    /** Removes a HostingProvider. */
    @Adjacency(label = "knows")
    void removeHostingProvider(final HostingProvider region);

    /** Returns the HostingProvider with the given name, if any. */
    @GremlinGroovy("it.out('knows').has('name',name)")
    HostingProvider findRegion(@GremlinParam("name") final String name);
}
