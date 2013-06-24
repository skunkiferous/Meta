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

import com.blockwithme.meta.types.Named;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * An hosting provider provides hardware and/or virtual nodes, that we can
 * rent, to run our JVMs and applications.
 *
 * We assume Regions are statically configured...
 *
 * @author monster
 */
@TypeValue("HostingProvider")
public interface HostingProvider extends Named {
    /** Return the hosting provider's regions. */
    @Adjacency(label = "offers")
    Region[] getRegions();

    /** Adds a region. */
    @Adjacency(label = "offers")
    void addRegion(final Region region);

    /** Removes a region. */
    @Adjacency(label = "offers")
    void removeRegion(final Region region);

    /** Returns the Region with the given name, if any. */
    @GremlinGroovy("it.out('offers').has('name',name)")
    Region findRegion(@GremlinParam("name") final String name);
}
