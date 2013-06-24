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
 * An availability zone is a geographically distinct area on the globe, where
 * an hosting provider can have inter-linked data-centers.
 *
 * We assume DataCenters are statically configured...
 *
 * @author monster
 */
@TypeValue("AvailabilityZone")
public interface AvailabilityZone extends Named {
    /** Returns the data-centers in this availability zone. */
    @Adjacency(label = "contains")
    DataCenter[] getDataCenters();

    /** Adds an data-center. */
    @Adjacency(label = "contains")
    void addDataCenter(final DataCenter dataCenter);

    /** Removes an data-center. */
    @Adjacency(label = "contains")
    void removeDataCenter(final DataCenter dataCenter);

    /** Returns the data-center with the given name, if any. */
    @GremlinGroovy("it.out('contains').has('name',name)")
    DataCenter findDataCenter(@GremlinParam("name") final String name);
}
