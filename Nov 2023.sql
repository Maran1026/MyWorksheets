CREATE OR REPLACE TABLE test_fixed(num NUMBER,
                                    num10 NUMBER(10,1),
                                    dec DECIMAL(20,2),
                                    numeric NUMERIC(30,3),
                                    int INT,
                                    integer INTEGER,
                                    f float
                                    );

desc table test_fixed;

insert into test_fixed
values (10.11,10.11,10.11,10.11,10.11,10.11,10.11);

select * from test_fixed;