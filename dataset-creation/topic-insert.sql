LOCK TABLES topic WRITE;
INSERT INTO topic (refId, value, weight, url) VALUES
('pizza','pizza',0.255, ''),
('italian','italian',0.231, ''),
('regional','regional',0.084, ''),
('chinese','chinese',0.068, ''),
('seafood','seafood',0.063, ''),
('japanese','japanese',0.06, ''),
('sushi','sushi',0.047, ''),
('asian','asian',0.021, ''),
('burger','burger',0.013, '');
UNLOCK TABLES;
