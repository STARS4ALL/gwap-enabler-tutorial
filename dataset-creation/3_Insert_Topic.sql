/* 
 * (C) Copyright 2018 CEFRIEL (http://www.cefriel.com/).
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Contributors:
 *     Andrea Fiano, Gloria Re Calegari, Irene Celino.
 */
 
LOCK TABLES topic WRITE;
INSERT INTO topic (refId, value, weight, url) VALUES
('pizza','pizza',0.254, ''),
('italian','italian',0.23, ''),
('regional','regional',0.084, ''),
('chinese','chinese',0.068, ''),
('japanese','japanese',0.063, ''),
('seafood','seafood',0.063, ''),
('sushi','sushi',0.047, ''),
('asian','asian',0.021, ''),
('burger','burger',0.013, '');
UNLOCK TABLES;
